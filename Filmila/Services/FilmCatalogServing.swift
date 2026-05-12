import Foundation

enum FilmCatalogError: LocalizedError, Equatable {
    case supabaseNotConfigured
    case notSignedIn
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .supabaseNotConfigured:
            return String(localized: "error_film_catalog_supabase_not_configured")
        case .notSignedIn:
            return String(localized: "error_film_catalog_not_signed_in")
        case .decodingFailed:
            return String(localized: "error_film_catalog_decoding_failed")
        }
    }
}

protocol FilmCatalogServing: Sendable {
    func films() async throws -> [Film]
    /// Resolves access using `film.price` and `film_payments` with `status == completed` for the current viewer.
    func canViewerWatch(filmId: Int) async throws -> Bool
}
