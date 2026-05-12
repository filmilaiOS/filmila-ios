import SwiftUI

private struct AppContainerKey: EnvironmentKey {
    static let defaultValue: any AppContainer = LiveAppContainer()
}

extension EnvironmentValues {
    var container: AppContainer {
        get { self[AppContainerKey.self] }
        set { self[AppContainerKey.self] = newValue }
    }
}
