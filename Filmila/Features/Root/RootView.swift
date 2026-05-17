import SwiftUI

struct RootView: View {
    @EnvironmentObject private var auth: AuthService
    @Environment(\.container) private var container
    /// Ensures `restoreSession()` runs at most once for this `RootView` lifetime, even if SwiftUI restarts `.task`.
    @State private var didRunAuthBootstrap = false

    var body: some View {
        Group {
            if auth.isLoading {
                SplashView()
            } else if auth.session == nil {
                AuthNavigationStack()
            } else {
                MainTabView(container: container)
            }
        }
        .onChange(of: auth.session?.user.id.uuidString) { newValue in
#if DEBUG
            print("[FilmilaAuth] RootView session user id changed → \(newValue ?? "nil") (session is \(newValue == nil ? "nil" : "non-nil"))")
#endif
        }
        .task {
            let shouldBootstrap = await MainActor.run {
                if didRunAuthBootstrap { return false }
                didRunAuthBootstrap = true
                return true
            }
            guard shouldBootstrap else {
#if DEBUG
                print("[FilmilaAuth] RootView bootstrap skipped (already ran)")
#endif
                return
            }
#if DEBUG
            print("[FilmilaAuth] RootView starting one-shot auth bootstrap instance=\(ObjectIdentifier(auth))")
#endif
            await auth.restoreSession()
        }
    }
}

#if DEBUG
#Preview {
    let container = PreviewContainer()
    RootView()
        .environment(\.container, container)
        .environmentObject(PreviewContainer.makeSignedInAuthForPreviews())
        .environmentObject(container.pathMonitor)
        .environmentObject(container.deepLinkHandler)
        .preferredColorScheme(.dark)
}
#endif
