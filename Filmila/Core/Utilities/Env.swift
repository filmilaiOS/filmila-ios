import Foundation

enum Env {
    /// Defaults when `Info.plist` still contains `$(FILMILA_…)` or is empty (must match `*.xcconfig` / Xcode build settings).
    private static let bundledDefaultSupabaseURL = URL(string: "https://xvixqivyecroogmhktdr.supabase.co")!
    private static let bundledDefaultSupabaseAnonKey =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh2aXhxaXZ5ZWNyb29nbWhrdGRyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU0MDAxNjksImV4cCI6MjA2MDk3NjE2OX0.H9lB71-5ntdsIw-vXKd1v_w8QL30vYDT4r7IIsd6aaI"
    private static let bundledDefaultAPIBaseURL = URL(string: "https://api.filmila.app")!

    private static func plistString(_ key: String) -> String {
        let raw = (Bundle.main.object(forInfoDictionaryKey: key) as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if raw.isEmpty || raw.contains("$(") {
            return ""
        }
        return raw
    }

    static var supabaseURL: URL {
        let raw = plistString("SUPABASE_URL")
        if let url = URL(string: raw),
           url.scheme == "https",
           let host = url.host,
           !host.isEmpty {
            return url
        }
        return bundledDefaultSupabaseURL
    }

    static var supabaseAnonKey: String {
        let key = plistString("SUPABASE_ANON_KEY")
        if !key.isEmpty {
            return key
        }
        return bundledDefaultSupabaseAnonKey
    }

    /// Base URL for Vercel `/api/*` routes (no trailing slash required).
    static var apiBaseURL: URL {
        let raw = plistString("API_BASE_URL")
        if let url = URL(string: raw), url.scheme == "https", url.host?.isEmpty == false {
            if var components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                var path = components.path
                while path.hasSuffix("/"), path.count > 1 {
                    path.removeLast()
                }
                components.path = path
                if let normalized = components.url {
                    return normalized
                }
            }
            return url
        }
        return bundledDefaultAPIBaseURL
    }
}
