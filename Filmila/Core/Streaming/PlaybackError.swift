import Foundation

enum PlaybackError: LocalizedError {
    case streamUnavailable
    case loadTimeout
    case signInRequired
    case signingTimeout

    var errorDescription: String? {
        switch self {
        case .streamUnavailable:
            return String(localized: "player_error_unavailable")
        case .loadTimeout, .signingTimeout:
            return String(localized: "player_error_timeout")
        case .signInRequired:
            return String(localized: "player_error_sign_in")
        }
    }
}
