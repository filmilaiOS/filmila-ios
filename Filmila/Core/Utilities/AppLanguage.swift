import SwiftUI

enum AppLanguage {
    static let storageKey = "app_preferred_language"

    static var preferredCode: String {
        let stored = UserDefaults.standard.string(forKey: storageKey) ?? "en"
        return stored == "ar" ? "ar" : "en"
    }

    static var prefersArabic: Bool {
        preferredCode == "ar"
    }

    static var locale: Locale {
        Locale(identifier: preferredCode)
    }

    static var layoutDirection: LayoutDirection {
        prefersArabic ? .rightToLeft : .leftToRight
    }
}
