import Foundation

protocol AppContainer: Sendable {
    var filmCatalog: FilmCatalogServing { get }
}

struct LiveAppContainer: AppContainer {
    let filmCatalog: FilmCatalogServing

    init(configuration: AppConfiguration) {
        if let live = LiveFilmCatalogService(configuration: configuration) {
            filmCatalog = live
        } else {
            filmCatalog = UnavailableFilmCatalogService()
        }
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

#if DEBUG
actor PreviewFilmCatalogService: FilmCatalogServing {
    func films() async throws -> [Film] {
        [
            Film(id: 1, title: "Sample Short", synopsis: "Preview synopsis.", price: 0),
            Film(id: 2, title: "Paid Film", synopsis: nil, price: 12)
        ]
    }

    func canViewerWatch(filmId: Int) async throws -> Bool {
        true
    }
}

#endif
