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

    private(set) var currentFilmId: Int?
    private weak var networkMonitor: (any NetworkMonitorProtocol)?

    private let s3Service: S3SignedURLServiceProtocol
    private let progressRepo: ProgressRepositoryProtocol

    private var preparedFilm: Film?
    private var observedItem: AVPlayerItem?
    private var stallRecoveryCount = 0
    private let maxStallRecoveries = 2
    private var isRecoveringFromStall = false

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
        cleanup()
        preparedFilm = film
        currentFilmId = film.id
        stallRecoveryCount = 0
        playbackState = .loading
        isBuffering = true

        configureAudioSession()

        let url = try await resolvePlaybackURL(for: film, forceSignedRefresh: false)
        print("[FilmilaPlayback] prepare filmId=\(film.id) urlHost=\(url.host ?? "?")")

        try await startPlayer(with: url, resumeFrom: resumeFrom)
    }

    private func startPlayer(with url: URL, resumeFrom: FilmProgress?) async throws {
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

        try await waitForPlayerItemReady(item)

        if let resumeFrom, resumeFrom.progressSeconds > 10 {
            let seekTime = CMTime(seconds: Double(resumeFrom.progressSeconds), preferredTimescale: 600)
            await newPlayer.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero)
        }

        newPlayer.play()
        playbackState = .playing
        isBuffering = false
    }

    private func observeStalls(for item: AVPlayerItem) {
        stallStatusObservation = item.observe(\.status, options: [.new]) { [weak self] observed, _ in
            Task { @MainActor in
                guard let self else { return }
                guard observed === self.observedItem else { return }
                if observed.status == .failed {
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
                await self?.handleStall()
            }
        }
    }

    private func observeBuffering(for item: AVPlayerItem) {
        bufferEmptyObservation = item.observe(\.isPlaybackBufferEmpty, options: [.new]) { [weak self] observed, change in
            Task { @MainActor in
                guard let self else { return }
                guard observed === self.observedItem else { return }
                if change.newValue == true {
                    self.isBuffering = true
                }
            }
        }
        bufferLikelyObservation = item.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] observed, change in
            Task { @MainActor in
                guard let self else { return }
                guard observed === self.observedItem else { return }
                if change.newValue == true {
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
        guard !isRecoveringFromStall else { return }
        let ns = item.error as NSError?
        print("[FilmilaPlayback] item failed filmId=\(currentFilmId ?? -1) error=\(ns?.localizedDescription ?? "unknown") code=\(ns?.code ?? 0)")
        await handleStall()
    }

    func handleStall() async {
        guard let film = preparedFilm else { return }
        guard !isRecoveringFromStall else { return }
        guard stallRecoveryCount < maxStallRecoveries else {
            playbackState = .failed(String(localized: "player_error_unavailable"))
            isBuffering = false
            return
        }

        isRecoveringFromStall = true
        defer { isRecoveringFromStall = false }

        stallRecoveryCount += 1
        playbackState = .stalled
        isBuffering = true

        let resumeSeconds = CMTimeGetSeconds(player?.currentTime() ?? .zero)

        do {
            let url = try await resolvePlaybackURL(for: film, forceSignedRefresh: true)
            let asset = AVURLAsset(url: url)
            let item = AVPlayerItem(asset: asset)
            item.preferredForwardBufferDuration = 30

            removeItemObservers()
            observedItem = item
            observeStalls(for: item)
            observeBuffering(for: item)

            player?.replaceCurrentItem(with: item)
            try await waitForPlayerItemReady(item)

            if resumeSeconds.isFinite, resumeSeconds > 0 {
                let seekTime = CMTime(seconds: resumeSeconds, preferredTimescale: 600)
                await player?.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero)
            }

            player?.play()
            playbackState = .playing
            isBuffering = false
        } catch {
            playbackState = .failed((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
            isBuffering = false
        }
    }

    func handleNetworkChange(isConnected: Bool) {
        if isConnected {
            switch playbackState {
            case .stalled:
                Task { await handleStall() }
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
        removeItemObservers()

        if let obs = timeObserver, let player {
            player.removeTimeObserver(obs)
        }
        timeObserver = nil

        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        observedItem = nil
        preparedFilm = nil
        currentFilmId = nil
        stallRecoveryCount = 0
        isRecoveringFromStall = false
        playbackState = .idle
        currentTime = 0
        duration = 0
        isBuffering = false
    }

    private func resolvePlaybackURL(for film: Film, forceSignedRefresh: Bool) async throws -> URL {
        if !forceSignedRefresh, let direct = film.directPlaybackURL {
            return direct
        }
        if forceSignedRefresh {
            s3Service.invalidateCache(filmId: film.id)
        }
        return try await s3Service.fetchPlaybackURL(filmId: film.id)
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .moviePlayback)
        try? session.setActive(true)
    }

    private func waitForPlayerItemReady(_ item: AVPlayerItem, timeout: TimeInterval = 45) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            switch item.status {
            case .readyToPlay:
                return
            case .failed:
                throw item.error ?? PlaybackError.streamUnavailable
            default:
                try await Task.sleep(nanoseconds: 100_000_000)
            }
        }
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
    }
}
