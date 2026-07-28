import AVFoundation
import Foundation

enum PlaybackState: Equatable {
    case idle
    case loading
    case playing
    case paused
    case stalled
    case failed(String)

    static func == (lhs: PlaybackState, rhs: PlaybackState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.playing, .playing), (.paused, .paused), (.stalled, .stalled):
            return true
        case let (.failed(a), .failed(b)):
            return a == b
        default:
            return false
        }
    }
}

@MainActor
final class HLSPlayerService: ObservableObject {
    @Published private(set) var player: AVPlayer?
    @Published private(set) var playbackState: PlaybackState = .idle
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var duration: Double = 0
    @Published private(set) var isBuffering: Bool = false

    private(set) var timeObserver: Any?
    private var stallStatusObservation: NSKeyValueObservation?
    private var stalledNotificationToken: NSObjectProtocol?
    private var bufferEmptyObservation: NSKeyValueObservation?
    private var bufferLikelyObservation: NSKeyValueObservation?
    private var timeControlStatusObservation: NSKeyValueObservation?
    private var playerRateObservation: NSKeyValueObservation?
    private var failedToEndNotificationToken: NSObjectProtocol?

    private(set) var currentFilmId: Int?
    private weak var networkMonitor: (any NetworkMonitorProtocol)?

    private let s3Service: S3SignedURLServiceProtocol
    private let progressRepo: ProgressRepositoryProtocol

    private var preparedFilm: Film?
    private var observedItem: AVPlayerItem?
    private var stallRecoveryCount = 0
    private let maxStallRecoveries = 2
    private var isRecoveringFromStall = false
    /// Stall-recovery-specific: cancellable so `cleanup()` on dismiss does not wait on stuck AVFoundation work.
    private var stallRecoveryTask: Task<Void, Never>?
    /// Stall-recovery-specific: short readiness cap (initial `preparePlayback` keeps the default 45s wait).
    private let stallRecoveryReadyTimeout: TimeInterval = 8

    init(
        s3Service: S3SignedURLServiceProtocol,
        progressRepo: ProgressRepositoryProtocol,
        networkMonitor: any NetworkMonitorProtocol
    ) {
        self.s3Service = s3Service
        self.progressRepo = progressRepo
        self.networkMonitor = networkMonitor
    }

    func preparePlayback(film: Film, resumeFrom: FilmProgress?) async throws {
        PlaybackLogger.log(
            "preparePlayback START title=\(film.displayTitle) hlsUrl=\(film.hlsUrl ?? "nil") videoUrl=\(film.videoUrl ?? "nil") resumeSeconds=\(resumeFrom?.progressSeconds ?? 0)",
            filmId: film.id
        )
        cleanup()
        preparedFilm = film
        currentFilmId = film.id
        stallRecoveryCount = 0
        playbackState = .loading
        isBuffering = true

        configureAudioSession()

        PlaybackLogger.log("resolvePlaybackURL START forceSignedRefresh=false", filmId: film.id)
        let url = try await resolvePlaybackURL(for: film, forceSignedRefresh: false)
        PlaybackLogger.log("resolvePlaybackURL SUCCESS url=\(PlaybackLogger.redactedURL(url))", filmId: film.id)

        try await startPlayer(with: url, resumeFrom: resumeFrom)
        PlaybackLogger.log("preparePlayback COMPLETE state=\(playbackState)", filmId: film.id)
    }

    private func startPlayer(with url: URL, resumeFrom: FilmProgress?) async throws {
        PlaybackLogger.log("startPlayer START url=\(PlaybackLogger.redactedURL(url))", filmId: currentFilmId)
        let asset = AVURLAsset(url: url, options: [
            AVURLAssetPreferPreciseDurationAndTimingKey: false
        ])
        let item = AVPlayerItem(asset: asset)
        item.preferredForwardBufferDuration = 30

        let newPlayer = AVPlayer(playerItem: item)
        player = newPlayer
        observedItem = item

        observeStalls(for: item)
        observeBuffering(for: item)
        observeProgress(for: newPlayer)
        observePlayerDiagnostics(for: newPlayer, item: item)

        PlaybackLogger.log(
            "waitForPlayerItemReady START initialStatus=\(PlaybackLogger.playerItemStatus(item.status)) timeout=45s",
            filmId: currentFilmId
        )
        try await waitForPlayerItemReady(item)
        PlaybackLogger.log(
            "waitForPlayerItemReady SUCCESS status=\(PlaybackLogger.playerItemStatus(item.status)) duration=\(CMTimeGetSeconds(item.duration))",
            filmId: currentFilmId
        )

        if let resumeFrom, resumeFrom.progressSeconds > 10 {
            PlaybackLogger.log("seeking to resume position \(resumeFrom.progressSeconds)s", filmId: currentFilmId)
            let seekTime = CMTime(seconds: Double(resumeFrom.progressSeconds), preferredTimescale: 600)
            await newPlayer.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero)
        }

        PlaybackLogger.log(
            "calling play() rate=\(newPlayer.rate) timeControlStatus=\(PlaybackLogger.timeControlStatus(newPlayer.timeControlStatus))",
            filmId: currentFilmId
        )
        newPlayer.play()
        playbackState = .playing
        isBuffering = false
        PlaybackLogger.log(
            "startPlayer COMPLETE rate=\(newPlayer.rate) timeControlStatus=\(PlaybackLogger.timeControlStatus(newPlayer.timeControlStatus))",
            filmId: currentFilmId
        )
    }

    private func observeStalls(for item: AVPlayerItem) {
        PlaybackLogger.log(
            "observeStalls attached initialStatus=\(PlaybackLogger.playerItemStatus(item.status))",
            filmId: currentFilmId
        )
        stallStatusObservation = item.observe(\.status, options: [.new, .initial]) { [weak self] observed, change in
            Task { @MainActor in
                guard let self else { return }
                guard observed === self.observedItem else { return }
                let status = observed.status
                PlaybackLogger.log(
                    "AVPlayerItem.status KVO → \(PlaybackLogger.playerItemStatus(status)) (was=\(change.oldValue.map { PlaybackLogger.playerItemStatus($0) } ?? "nil"))",
                    filmId: self.currentFilmId
                )
                if status == .failed {
                    PlaybackLogger.logError(
                        "AVPlayerItem.status failed item.error",
                        error: observed.error,
                        filmId: self.currentFilmId
                    )
                    if let itemError = observed.errorLog()?.events.last {
                        PlaybackLogger.log(
                            "AVPlayerItem errorLog last event: \(itemError.errorComment ?? "no comment") status=\(itemError.errorStatusCode)",
                            filmId: self.currentFilmId
                        )
                    }
                    await self.handlePlaybackFailure(item: observed)
                }
            }
        }

        stalledNotificationToken = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemPlaybackStalled,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                PlaybackLogger.log("notification AVPlayerItemPlaybackStalled", filmId: self?.currentFilmId)
                self?.scheduleStallRecovery()
            }
        }
    }

    private func observePlayerDiagnostics(for player: AVPlayer, item: AVPlayerItem) {
        timeControlStatusObservation = player.observe(\.timeControlStatus, options: [.new, .initial]) { [weak self] observed, change in
            Task { @MainActor in
                guard let self else { return }
                let status = observed.timeControlStatus
                PlaybackLogger.log(
                    "AVPlayer.timeControlStatus KVO → \(PlaybackLogger.timeControlStatus(status)) reason=\(PlaybackLogger.waitingReason(observed.reasonForWaitingToPlay)) (was=\(change.oldValue.map { PlaybackLogger.timeControlStatus($0) } ?? "nil"))",
                    filmId: self.currentFilmId
                )
            }
        }

        playerRateObservation = player.observe(\.rate, options: [.new, .initial]) { [weak self] observed, change in
            Task { @MainActor in
                PlaybackLogger.log(
                    "AVPlayer.rate KVO → \(observed.rate) (was=\(change.oldValue ?? -1))",
                    filmId: self?.currentFilmId
                )
            }
        }

        failedToEndNotificationToken = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
                PlaybackLogger.logError(
                    "notification AVPlayerItemFailedToPlayToEndTime",
                    error: error,
                    filmId: self?.currentFilmId
                )
            }
        }
    }

    private func observeBuffering(for item: AVPlayerItem) {
        bufferEmptyObservation = item.observe(\.isPlaybackBufferEmpty, options: [.new]) { [weak self] observed, change in
            Task { @MainActor in
                guard let self else { return }
                guard observed === self.observedItem else { return }
                if change.newValue == true {
                    PlaybackLogger.log("AVPlayerItem.isPlaybackBufferEmpty → true", filmId: self.currentFilmId)
                    self.isBuffering = true
                }
            }
        }
        bufferLikelyObservation = item.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] observed, change in
            Task { @MainActor in
                guard let self else { return }
                guard observed === self.observedItem else { return }
                if change.newValue == true {
                    PlaybackLogger.log("AVPlayerItem.isPlaybackLikelyToKeepUp → true", filmId: self.currentFilmId)
                    self.isBuffering = false
                }
            }
        }
    }

    private func observeProgress(for player: AVPlayer) {
        let interval = CMTime(seconds: 10, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                self?.progressTick(time: time)
            }
        }
    }

    private func progressTick(time: CMTime) {
        guard let player, let filmId = currentFilmId else { return }
        let seconds = CMTimeGetSeconds(time)
        guard seconds.isFinite else { return }
        currentTime = seconds

        if let item = player.currentItem {
            let d = CMTimeGetSeconds(item.duration)
            if d.isFinite, d > 0 {
                duration = d
            }
        }

        Task {
            let secs = Int(floor(seconds))
            guard secs > 0 else { return }
            try? await progressRepo.saveProgress(filmId: filmId, seconds: secs)
        }
    }

    private func handlePlaybackFailure(item: AVPlayerItem) async {
        guard !isRecoveringFromStall else {
            PlaybackLogger.log("handlePlaybackFailure skipped — already recovering from stall", filmId: currentFilmId)
            return
        }
        PlaybackLogger.logError("handlePlaybackFailure", error: item.error, filmId: currentFilmId)
        scheduleStallRecovery()
    }

    // MARK: - Stall recovery (UI-responsiveness fixes; server-side faststart/HLS is the long-term fix)

    /// Schedules stall recovery on a cancellable task so `cleanup()` / dismiss are not blocked by `await handleStall()`.
    /// When `maxStallRecoveries == 0`, fail immediately — re-fetching the same CloudFront/S3 object cannot fix bitrate/faststart issues.
    func scheduleStallRecovery() {
        guard preparedFilm != nil else {
            PlaybackLogger.log("scheduleStallRecovery aborted — no preparedFilm")
            return
        }
        if maxStallRecoveries == 0 {
            PlaybackLogger.log(
                "scheduleStallRecovery fail-fast — skipping recovery (same URL cannot fix progressive stall)",
                filmId: currentFilmId
            )
            player?.pause()
            playbackState = .failed(String(localized: "player_error_unavailable"))
            isBuffering = false
            return
        }
        if let stallRecoveryTask, !stallRecoveryTask.isCancelled {
            PlaybackLogger.log("scheduleStallRecovery skipped — recovery task already running", filmId: currentFilmId)
            return
        }
        stallRecoveryTask?.cancel()
        stallRecoveryTask = Task { @MainActor in
            await performStallRecovery()
        }
    }

    private func performStallRecovery() async {
        guard let film = preparedFilm else {
            PlaybackLogger.log("performStallRecovery aborted — no preparedFilm")
            return
        }
        if Task.isCancelled {
            PlaybackLogger.log("performStallRecovery aborted — task cancelled before start", filmId: film.id)
            return
        }
        guard !isRecoveringFromStall else {
            PlaybackLogger.log("performStallRecovery skipped — already recovering", filmId: film.id)
            return
        }
        guard stallRecoveryCount < maxStallRecoveries else {
            PlaybackLogger.log(
                "performStallRecovery fail-fast — stall retries exhausted (\(maxStallRecoveries))",
                filmId: film.id
            )
            playbackState = .failed(String(localized: "player_error_unavailable"))
            isBuffering = false
            return
        }

        isRecoveringFromStall = true
        defer {
            isRecoveringFromStall = false
            stallRecoveryTask = nil
        }

        stallRecoveryCount += 1
        PlaybackLogger.log(
            "performStallRecovery attempt \(stallRecoveryCount)/\(maxStallRecoveries) readyTimeout=\(stallRecoveryReadyTimeout)s",
            filmId: film.id
        )
        playbackState = .stalled
        isBuffering = true

        let resumeSeconds = CMTimeGetSeconds(player?.currentTime() ?? .zero)

        do {
            try Task.checkCancellation()
            PlaybackLogger.log("performStallRecovery resolvePlaybackURL forceSignedRefresh=true", filmId: film.id)
            let url = try await resolvePlaybackURL(for: film, forceSignedRefresh: true)
            try Task.checkCancellation()
            PlaybackLogger.log("performStallRecovery got URL=\(PlaybackLogger.redactedURL(url))", filmId: film.id)

            // Build asset/item off the main actor — only `replaceCurrentItem` / `play()` touch AVPlayer here.
            let item = await StallRecoveryAssetBuilder.buildPlayerItem(for: url)
            try Task.checkCancellation()

            removeItemObservers()
            observedItem = item
            observeStalls(for: item)
            observeBuffering(for: item)

            player?.replaceCurrentItem(with: item)

            try await StallRecoveryAssetBuilder.waitUntilReady(
                item,
                timeout: stallRecoveryReadyTimeout,
                filmId: film.id
            )
            try Task.checkCancellation()

            if resumeSeconds.isFinite, resumeSeconds > 0 {
                let seekTime = CMTime(seconds: resumeSeconds, preferredTimescale: 600)
                await player?.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero)
            }

            player?.play()
            playbackState = .playing
            isBuffering = false
            PlaybackLogger.log("performStallRecovery SUCCESS", filmId: film.id)
        } catch is CancellationError {
            PlaybackLogger.log("performStallRecovery CANCELLED (dismiss/cleanup)", filmId: film.id)
        } catch {
            PlaybackLogger.logError("performStallRecovery FAILED", error: error, filmId: film.id)
            playbackState = .failed((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
            isBuffering = false
        }
    }

    func handleNetworkChange(isConnected: Bool) {
        PlaybackLogger.log(
            "handleNetworkChange isConnected=\(isConnected) playbackState=\(playbackState)",
            filmId: currentFilmId
        )
        if isConnected {
            switch playbackState {
            case .stalled:
                scheduleStallRecovery()
            case .paused where player != nil:
                player?.play()
                playbackState = .playing
            default:
                break
            }
        } else {
            player?.pause()
            if case .playing = playbackState {
                playbackState = .paused
            }
        }
    }

    func cleanup() {
        PlaybackLogger.log("cleanup START", filmId: currentFilmId)
        // Cancel recovery first so dismiss never waits on AVFoundation work.
        stallRecoveryTask?.cancel()
        stallRecoveryTask = nil
        isRecoveringFromStall = false

        removeItemObservers()

        if let obs = timeObserver, let player {
            player.removeTimeObserver(obs)
        }
        timeObserver = nil

        player?.pause()
        // Release the player without replaceCurrentItem(with: nil) — that call can block the main
        // thread while tearing down a large progressive download (e.g. 458 MB .mov).
        player = nil
        observedItem = nil
        preparedFilm = nil
        currentFilmId = nil
        stallRecoveryCount = 0
        playbackState = .idle
        currentTime = 0
        duration = 0
        isBuffering = false
        PlaybackLogger.log("cleanup COMPLETE")
    }

    private func resolvePlaybackURL(for film: Film, forceSignedRefresh: Bool) async throws -> URL {
        PlaybackLogger.log(
            "resolvePlaybackURL catalog hlsUrl=\(film.hlsUrl ?? "nil") videoUrl=\(film.videoUrl ?? "nil") directPlaybackURL=\(film.directPlaybackURL.map { PlaybackLogger.redactedURL($0) } ?? "nil") forceSignedRefresh=\(forceSignedRefresh)",
            filmId: film.id
        )
        if !forceSignedRefresh, let direct = film.directPlaybackURL {
            PlaybackLogger.log("resolvePlaybackURL using direct catalog URL (no signing)", filmId: film.id)
            return direct
        }
        if forceSignedRefresh {
            PlaybackLogger.log("resolvePlaybackURL invalidating signed URL cache", filmId: film.id)
            s3Service.invalidateCache(filmId: film.id)
        }
        PlaybackLogger.log("resolvePlaybackURL fetching signed URL via S3SignedURLService", filmId: film.id)
        return try await s3Service.fetchPlaybackURL(filmId: film.id)
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .moviePlayback)
            try session.setActive(true)
            PlaybackLogger.log("AVAudioSession configured category=playback mode=moviePlayback", filmId: currentFilmId)
        } catch {
            PlaybackLogger.logError("AVAudioSession configuration FAILED", error: error, filmId: currentFilmId)
        }
    }

    private func waitForPlayerItemReady(_ item: AVPlayerItem, timeout: TimeInterval = 45) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        var lastLoggedStatus: AVPlayerItem.Status?
        var waitStarted = Date()
        var lastProgressLog = waitStarted
        while Date() < deadline {
            let status = item.status
            if status != lastLoggedStatus {
                PlaybackLogger.log(
                    "waitForPlayerItemReady status=\(PlaybackLogger.playerItemStatus(status)) elapsed=\(String(format: "%.1f", Date().timeIntervalSince(waitStarted)))s",
                    filmId: currentFilmId
                )
                lastLoggedStatus = status
            }
            switch status {
            case .readyToPlay:
                return
            case .failed:
                PlaybackLogger.logError("waitForPlayerItemReady item failed", error: item.error, filmId: currentFilmId)
                throw item.error ?? PlaybackError.streamUnavailable
            default:
                let now = Date()
                if now.timeIntervalSince(lastProgressLog) >= 5 {
                    lastProgressLog = now
                    PlaybackLogger.log(
                        "waitForPlayerItemReady still waiting status=\(PlaybackLogger.playerItemStatus(status)) isPlaybackLikelyToKeepUp=\(item.isPlaybackLikelyToKeepUp) isPlaybackBufferEmpty=\(item.isPlaybackBufferEmpty)",
                        filmId: currentFilmId
                    )
                }
                try await Task.sleep(nanoseconds: 100_000_000)
            }
        }
        PlaybackLogger.log(
            "waitForPlayerItemReady TIMEOUT after \(timeout)s lastStatus=\(PlaybackLogger.playerItemStatus(item.status)) item.error=\(item.error?.localizedDescription ?? "nil")",
            filmId: currentFilmId
        )
        throw PlaybackError.loadTimeout
    }

    private func removeItemObservers() {
        stallStatusObservation?.invalidate()
        stallStatusObservation = nil
        if let stalledNotificationToken {
            NotificationCenter.default.removeObserver(stalledNotificationToken)
        }
        stalledNotificationToken = nil
        bufferEmptyObservation?.invalidate()
        bufferEmptyObservation = nil
        bufferLikelyObservation?.invalidate()
        bufferLikelyObservation = nil
        timeControlStatusObservation?.invalidate()
        timeControlStatusObservation = nil
        playerRateObservation?.invalidate()
        playerRateObservation = nil
        if let failedToEndNotificationToken {
            NotificationCenter.default.removeObserver(failedToEndNotificationToken)
        }
        failedToEndNotificationToken = nil
    }
}

// MARK: - Stall recovery asset builder (off-main-thread; stall-recovery path only)

/// Keeps heavy `AVURLAsset` / readiness polling off `@MainActor` during stall recovery.
/// Initial `preparePlayback` / `startPlayer` are unchanged and still use main-actor construction.
private enum StallRecoveryAssetBuilder {
    static func buildPlayerItem(for url: URL) async -> AVPlayerItem {
        await Task.detached(priority: .userInitiated) {
            let asset = AVURLAsset(url: url, options: [
                AVURLAssetPreferPreciseDurationAndTimingKey: false
            ])
            let item = AVPlayerItem(asset: asset)
            item.preferredForwardBufferDuration = 30
            return item
        }.value
    }

    static func waitUntilReady(_ item: AVPlayerItem, timeout: TimeInterval, filmId: Int?) async throws {
        try await Task.detached(priority: .utility) {
            let deadline = Date().addingTimeInterval(timeout)
            var lastLoggedStatus: AVPlayerItem.Status?
            var waitStarted = Date()
            while Date() < deadline {
                try Task.checkCancellation()
                let status = item.status
                if status != lastLoggedStatus {
                    PlaybackLogger.log(
                        "stallRecovery waitUntilReady status=\(PlaybackLogger.playerItemStatus(status)) elapsed=\(String(format: "%.1f", Date().timeIntervalSince(waitStarted)))s",
                        filmId: filmId
                    )
                    lastLoggedStatus = status
                }
                switch status {
                case .readyToPlay:
                    return
                case .failed:
                    PlaybackLogger.logError("stallRecovery waitUntilReady item failed", error: item.error, filmId: filmId)
                    throw item.error ?? PlaybackError.streamUnavailable
                default:
                    try await Task.sleep(nanoseconds: 100_000_000)
                }
            }
            PlaybackLogger.log(
                "stallRecovery waitUntilReady TIMEOUT after \(timeout)s lastStatus=\(PlaybackLogger.playerItemStatus(item.status))",
                filmId: filmId
            )
            throw PlaybackError.loadTimeout
        }.value
    }
}
