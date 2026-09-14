import SwiftUI

@main
struct FilmilaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @ObservedObject private var language = AppLanguageController.shared

    @StateObject private var auth: AuthService
    @StateObject private var networkMonitor: NetworkMonitor
    private let container: LiveAppContainer

    init() {
        LanguageBundleOverride.install()
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
                .environment(\.locale, language.locale)
                .environment(\.layoutDirection, language.layoutDirection)
                .environmentObject(language)
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
