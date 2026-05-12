import SwiftUI

@main
struct FilmilaApp: App {
    private let container = LiveAppContainer(configuration: .loadFromBundle())

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
                .preferredColorScheme(.dark)
        }
    }
}
