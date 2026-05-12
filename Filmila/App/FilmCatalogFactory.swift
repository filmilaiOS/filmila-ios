import Foundation

#if DEBUG
actor PreviewFilmCatalogService: FilmCatalogServing {
    func films() async throws -> [Film] {
        [
            Film(
                id: 1,
                title: "Sample Short",
                description: "Preview synopsis.",
                price: 0.0,
                status: .approved,
                viewCount: 0,
                createdAt: Date()
            ),
            Film(
                id: 2,
                title: "Paid Film",
                price: 12.0,
                status: .approved,
                viewCount: 0,
                createdAt: Date()
            )
        ]
    }

    func canViewerWatch(filmId: Int) async throws -> Bool {
        true
    }
}
#endif

enum FilmCatalogFactory {
    static func make(configuration: AppConfiguration) -> FilmCatalogServing {
        if let live = LiveFilmCatalogService(configuration: configuration) {
            return live
        }
        return UnavailableFilmCatalogService()
    }
}

private struct UnavailableFilmCatalogService: FilmCatalogServing {
    func films() async throws -> [Film] {
        throw FilmCatalogError.supabaseNotConfigured
    }

    func canViewerWatch(filmId: Int) async throws -> Bool {
        throw FilmCatalogError.supabaseNotConfigured
    }
}
