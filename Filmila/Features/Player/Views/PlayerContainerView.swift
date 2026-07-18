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

            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.filmilaIconClose)
                            .foregroundStyle(FilmilaColors.textPrimary.opacity(0.92))
                    }
                    .padding(Spacing.md)
                    Spacer()
                }
                Spacer()
            }
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
