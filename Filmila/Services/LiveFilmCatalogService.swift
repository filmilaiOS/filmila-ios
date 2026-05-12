import Foundation
import Supabase

actor LiveFilmCatalogService: FilmCatalogServing {
    private let configuration: AppConfiguration
    private let filmsRepository: FilmsRepositoryProtocol
    private let accessChecker: AccessCheckerProtocol

    init?(configuration: AppConfiguration) {
        guard configuration.isSupabaseConfigured else {
            return nil
        }
        self.configuration = configuration
        self.filmsRepository = LiveFilmsRepository()
        self.accessChecker = AccessChecker()
    }

    func films() async throws -> [Film] {
        guard configuration.isSupabaseConfigured else {
            throw FilmCatalogError.supabaseNotConfigured
        }
        return try await filmsRepository.fetchApprovedFilms()
    }

    func canViewerWatch(filmId: Int) async throws -> Bool {
        guard configuration.isSupabaseConfigured else {
            throw FilmCatalogError.supabaseNotConfigured
        }
        let film = try await filmsRepository.fetchFilm(id: filmId)
        return try await accessChecker.hasAccess(to: film)
    }
}
