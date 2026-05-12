import SwiftUI

struct RootView: View {
    @EnvironmentObject private var auth: AuthService
    @Environment(\.container) private var container

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
        .task {
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
