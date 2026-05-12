import Foundation

enum FilmCatalogError: LocalizedError, Equatable {
    case supabaseNotConfigured
    case notSignedIn
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .supabaseNotConfigured:
            return "Supabase is not configured."
        case .notSignedIn:
            return "You must be signed in to watch paid films."
        case .decodingFailed:
            return "Could not read film data."
        }
    }
}

protocol FilmCatalogServing: Sendable {
    func films() async throws -> [Film]
    /// Resolves access using `film.price` and `film_payments` with `status == completed` for the current viewer.
    func canViewerWatch(filmId: Int) async throws -> Bool
}
