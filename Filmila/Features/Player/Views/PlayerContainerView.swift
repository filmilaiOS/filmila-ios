import SwiftUI

struct PlayerContainerView: View {
    @ObservedObject var networkMonitor: NetworkMonitor

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: PlayerViewModel

    init(film: Film, container: AppContainer, networkMonitor: NetworkMonitor) {
        self.networkMonitor = networkMonitor
        _vm = StateObject(wrappedValue: PlayerViewModel(film: film, container: container, networkMonitor: networkMonitor))
    }

    var body: some View {
        ZStack {
            FilmilaColors.playerChrome.ignoresSafeArea()

            if vm.playerService.player != nil {
                VideoPlayerView(service: vm.playerService)
                    .ignoresSafeArea()
            }

            VStack {
                if !networkMonitor.isConnected {
                    NetworkStatusBanner(monitor: networkMonitor)
                }
                Spacer()
            }
            .animation(.easeInOut(duration: 0.22), value: networkMonitor.isConnected)

            if vm.isLoading {
                ProgressView()
                    .tint(FilmilaColors.textPrimary)
            }

            if vm.showRetry, let message = vm.errorMessage {
                VStack(spacing: Spacing.md) {
                    Text(message)
                        .font(.filmilaBody)
                        .foregroundStyle(FilmilaColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.lg)

                    Button(String(localized: "player_retry")) {
                        Task { try? await vm.retryPlayback() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(Spacing.lg)
            }
        }
        // Close sits above AVPlayerViewController in a safe-area inset so taps are not stolen by UIKit video chrome.
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                closeButton
                Spacer()
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.top, Spacing.xs)
            .background(Color.clear)
        }
        .task {
            PlaybackLogger.log("PlayerContainerView.task START — launching startPlayback()", filmId: vm.filmIdForLogging)
            do {
                try await vm.startPlayback()
                PlaybackLogger.log("PlayerContainerView.task startPlayback succeeded", filmId: vm.filmIdForLogging)
            } catch {
                PlaybackLogger.logError("PlayerContainerView.task startPlayback failed", error: error, filmId: vm.filmIdForLogging)
            }
        }
        .onDisappear {
            PlaybackLogger.log("PlayerContainerView.onDisappear — cleanup()", filmId: vm.filmIdForLogging)
            vm.cleanup()
        }
    }

    private var closeButton: some View {
        Button {
            closePlayer()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .symbolRenderingMode(.hierarchical)
                .font(.filmilaIconClose)
                .foregroundStyle(FilmilaColors.textPrimary.opacity(0.92))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(String(localized: "player_close")))
    }

    /// Stop AVFoundation work immediately, then dismiss — do not wait for `onDisappear` alone.
    private func closePlayer() {
        PlaybackLogger.log("PlayerContainerView.closePlayer — cleanup then dismiss", filmId: vm.filmIdForLogging)
        vm.cleanup()
        dismiss()
    }
}

#if DEBUG
#Preview {
    let container = PreviewContainer()
    let film = Film(
        id: 1,
        title: "Preview Playback",
        price: 0,
        status: .approved,
        viewCount: 0,
        createdAt: Date()
    )
    return PlayerContainerView(film: film, container: container, networkMonitor: container.pathMonitor)
        .environment(\.container, container)
}
#endif
