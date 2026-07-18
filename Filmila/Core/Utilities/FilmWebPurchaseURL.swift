import Foundation

enum FilmWebPurchaseURL {
    /// Mobile checkout page on filmila.com; authenticates via Supabase JWT in the query string.
    static func purchaseURL(forFilmId filmId: Int, accessToken: String) -> URL? {
        var components = URLComponents(
            url: Env.apiBaseURL.appendingPathComponent("mobile-checkout/\(filmId)", isDirectory: false),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "token", value: accessToken)]
        return components?.url
    }
}
