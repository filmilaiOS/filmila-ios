#if DEBUG
import Foundation

enum FilmWebPurchaseURL {
    /// Legacy mobile checkout helper. Not compiled into Reader App Release builds.
    static func purchaseURL(forFilmId filmId: Int, accessToken: String) -> URL? {
        var components = URLComponents(
            url: Env.apiBaseURL.appendingPathComponent("mobile-checkout/\(filmId)", isDirectory: false),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "token", value: accessToken)]
        return components?.url
    }
}
#endif
