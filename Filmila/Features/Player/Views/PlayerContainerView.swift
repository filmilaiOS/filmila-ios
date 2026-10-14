import SwiftUI
import WebKit
import Supabase

struct PlayerContainerView: View {
    @ObservedObject var networkMonitor: NetworkMonitor

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: PlayerViewModel
    @State private var isClosing = false
    @State private var bunnyURL: URL?
    @State private var bunnyLoading = false
    @State private var bunnyError: String?
    @State private var isBunny = false
    private let filmId: Int

    init(film: Film, container: AppContainer, networkMonitor: NetworkMonitor) {
        self.networkMonitor = networkMonitor
        self.filmId = film.id
        _vm = StateObject(wrappedValue: PlayerViewModel(film: film, container: container, networkMonitor: networkMonitor))
    }

    var body: some View {
        ZStack {
            FilmilaColors.playerChrome.ignoresSafeArea()

            if !isClosing, isBunny, let bunnyURL {
                BunnyEmbedView(url: bunnyURL).ignoresSafeArea()
            } else if !isClosing, !isBunny, vm.playerService.player != nil {
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

            if (isBunny ? bunnyLoading : vm.isLoading) && !isClosing {
                ProgressView()
                    .tint(FilmilaColors.textPrimary)
            }

            if (isBunny ? bunnyError != nil : vm.showRetry),
               let message = isBunny ? bunnyError : vm.errorMessage {
                VStack(spacing: Spacing.md) {
                    Text(message)
                        .font(.filmilaBody)
                        .foregroundStyle(FilmilaColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.lg)

                    Button(String(localized: "player_retry")) {
                        if isBunny { Task { await loadBunny() } }
                        else { Task { try? await vm.retryPlayback() } }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(Spacing.lg)
            }
        }
        .overlay(alignment: .topLeading) {
            closeButton
                .padding(.leading, Spacing.sm)
                .padding(.top, Spacing.xs)
                .zIndex(10)
        }
        .task {
            // Resolve the provider from the authoritative film row, not stale catalog fields.
            let provider = try? await SupabaseManager.shared.client.from("films")
                .select("video_provider").eq("id", value: filmId).single().execute()
            if let data = provider?.data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               json["video_provider"] as? String == "bunny" {
                isBunny = true
                await loadBunny()
                return
            }
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

    @MainActor
    private func loadBunny() async {
        bunnyLoading = true
        bunnyError = nil
        bunnyURL = nil
        defer { bunnyLoading = false }
        do {
            let token = try await SupabaseManager.shared.client.auth.session.accessToken
            var components = URLComponents(url: Env.apiBaseURL.appendingPathComponent("api/bunny-playback"), resolvingAgainstBaseURL: false)!
            components.queryItems = [URLQueryItem(name: "filmId", value: String(filmId))]
            var request = URLRequest(url: components.url!)
            request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw NSError(domain: "Filmila.Bunny", code: (response as? HTTPURLResponse)?.statusCode ?? -1,
                              userInfo: [NSLocalizedDescriptionKey: "Unable to authorize Bunny playback"])
            }
            let result = try JSONDecoder().decode(BunnyResult.self, from: data)
            guard result.provider == "bunny",
                  let url = URL(string: result.signedUrl),
                  url.scheme == "https", url.host == "player.mediadelivery.net",
                  url.path.hasPrefix("/embed/") else {
                throw NSError(domain: "Filmila.Bunny", code: -2,
                              userInfo: [NSLocalizedDescriptionKey: "Invalid protected video URL"])
            }
            bunnyURL = url
        } catch {
            bunnyError = error.localizedDescription
        }
    }

    private struct BunnyResult: Decodable {
        let signedUrl: String
        let provider: String
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
        guard !isClosing else { return }
        isClosing = true
        dismiss()
        // Releasing AVFoundation is deferred until the closing transition removes its UIKit view.
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

private struct BunnyEmbedView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let view = WKWebView(frame: .zero, configuration: config)
        view.isOpaque = false
        view.backgroundColor = .black
        return view
    }
    func updateUIView(_ view: WKWebView, context: Context) {
        guard context.coordinator.loadedURL != url else { return }
        context.coordinator.loadedURL = url
        let safeURL = url.absoluteString.replacingOccurrences(of: "&", with: "&amp;")
        let html = """
        <!doctype html><html><head><meta name="viewport" content="width=device-width, initial-scale=1">
        <style>html,body{margin:0;width:100%;height:100%;background:black}iframe{width:100%;height:100%;border:0}</style>
        </head><body><iframe src="\(safeURL)" allow="autoplay;fullscreen;picture-in-picture" allowfullscreen></iframe></body></html>
        """
        view.loadHTMLString(html, baseURL: URL(string: "https://www.filmila.com"))
    }
    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator { var loadedURL: URL? }
}
