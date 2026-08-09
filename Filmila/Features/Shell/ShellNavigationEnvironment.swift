import SwiftUI

enum AuthSheetDestination: Identifiable, Equatable {
    case login
    case register

    var id: String {
        switch self {
        case .login: return "login"
        case .register: return "register"
        }
    }
}

enum BrowseMenuDestination: Equatable {
    case films
    case collections
    case genres
    case moods
    case themes
    case myList
    case community
    case submitFilm
    case about
    case partners
    case help
    case profile
}

struct ShellNavigationActions {
    var openDrawer: () -> Void = {}
    var closeDrawer: () -> Void = {}
    var presentLogin: () -> Void = {}
    var presentRegister: () -> Void = {}
    var navigateBrowse: (BrowseMenuDestination) -> Void = { _ in }
}

private struct ShellNavigationActionsKey: EnvironmentKey {
    static let defaultValue = ShellNavigationActions()
}

extension EnvironmentValues {
    var shellNavigation: ShellNavigationActions {
        get { self[ShellNavigationActionsKey.self] }
        set { self[ShellNavigationActionsKey.self] = newValue }
    }
}
