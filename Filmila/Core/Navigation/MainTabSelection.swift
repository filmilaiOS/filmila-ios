import SwiftUI

private struct MainTabSelectionKey: EnvironmentKey {
    static let defaultValue: Binding<Int>? = nil
}

extension EnvironmentValues {
    /// Root tab index (`0` = Home). Set by `MainTabView` for in-app tab switching.
    var mainTabSelection: Binding<Int>? {
        get { self[MainTabSelectionKey.self] }
        set { self[MainTabSelectionKey.self] = newValue }
    }
}
