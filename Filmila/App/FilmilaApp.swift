import SwiftUI

@main
struct FilmilaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @AppStorage("app_preferred_language") private var appPreferredLanguage = "en"

    @StateObject private var auth: AuthService
    @StateObject private var networkMonitor: NetworkMonitor
    private let container: LiveAppContainer

    init() {
        let container = LiveAppContainer()
        LiveAppContainer.shared = container
        self.container = container
        _auth = StateObject(wrappedValue: container.sharedAuthService)
        _networkMonitor = StateObject(wrappedValue: container.pathMonitor)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.container, container)
                .environment(\.locale, Locale(identifier: appPreferredLanguage == "ar" ? "ar" : "en"))
                .environmentObject(auth)
                .environmentObject(networkMonitor)
                .environmentObject(container.deepLinkHandler)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    container.deepLinkHandler.handle(url)
                }
        }
    }
}
