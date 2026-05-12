import Foundation

struct AppConfiguration: Sendable {
    let supabaseURL: URL?
    let supabaseAnonKey: String

    var isSupabaseConfigured: Bool {
        guard let url = supabaseURL, url.scheme == "https" else { return false }
        let key = supabaseAnonKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return false }
        if key.contains("YOUR_SUPABASE_ANON_KEY") { return false }
        let host = url.host ?? ""
        if host.contains("YOUR_PROJECT_REF") { return false }
        return true
    }

    static func loadFromBundle(_ bundle: Bundle = .main) -> AppConfiguration {
        let urlString = (bundle.object(forInfoDictionaryKey: "SUPABASE_URL") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let key = (bundle.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let url = urlString.flatMap { URL(string: $0) }
        return AppConfiguration(supabaseURL: url, supabaseAnonKey: key)
    }
}
