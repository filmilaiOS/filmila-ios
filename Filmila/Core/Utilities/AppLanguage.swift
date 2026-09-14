import SwiftUI

/// In-app language override so `String(localized:)` / `NSLocalizedString` follow Filmila’s setting,
/// not the device system language. The `en.lproj` / `ar.lproj` bundles are used directly.
enum LanguageBundleOverride {
    static let storageKey = "app_preferred_language"

    private static let lock = NSLock()
    private static var _code: String = {
        let stored = UserDefaults.standard.string(forKey: storageKey) ?? "en"
        return stored == "ar" ? "ar" : "en"
    }()

    static var activeCode: String {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _code
        }
        set {
            lock.lock()
            _code = newValue == "ar" ? "ar" : "en"
            lock.unlock()
        }
    }

    static func install() {
        _ = installer
    }

    private static let installer: Void = {
        object_setClass(Bundle.main, FilmilaLanguageBundle.self)
    }()
}

/// `Bundle.main` subclass used only after `object_setClass`. Lookups go to the selected lproj.
final class FilmilaLanguageBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        let code = LanguageBundleOverride.activeCode
        if let path = path(forResource: code, ofType: "lproj"),
           let languageBundle = Bundle(path: path) {
            return languageBundle.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

/// Observable source of truth for in-app locale and layout direction.
@MainActor
final class AppLanguageController: ObservableObject {
    static let shared = AppLanguageController()

    @Published private(set) var code: String

    var locale: Locale { Locale(identifier: code) }
    var layoutDirection: LayoutDirection { code == "ar" ? .rightToLeft : .leftToRight }
    var prefersArabic: Bool { code == "ar" }

    private init() {
        LanguageBundleOverride.install()
        let stored = UserDefaults.standard.string(forKey: LanguageBundleOverride.storageKey) ?? "en"
        let normalized = stored == "ar" ? "ar" : "en"
        LanguageBundleOverride.activeCode = normalized
        UserDefaults.standard.set([normalized], forKey: "AppleLanguages")
        code = normalized
    }

    func select(_ raw: String) {
        let normalized = raw == "ar" ? "ar" : "en"
        guard normalized != code else { return }
        UserDefaults.standard.set(normalized, forKey: LanguageBundleOverride.storageKey)
        UserDefaults.standard.set([normalized], forKey: "AppleLanguages")
        LanguageBundleOverride.activeCode = normalized
        code = normalized
    }
}

enum AppLanguage {
    static let storageKey = LanguageBundleOverride.storageKey

    static var preferredCode: String {
        LanguageBundleOverride.activeCode
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
