import Foundation

struct ContinueWatchingItem: Identifiable, Equatable {
    let film: Film
    let progress: FilmProgress

    var id: Int { film.id }
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var featured: [Film] = []
    @Published private(set) var trending: [Film] = []
    @Published private(set) var recentlyAdded: [Film] = []
    @Published private(set) var continueWatchingItems: [ContinueWatchingItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    private let filmsRepo: FilmsRepositoryProtocol
    private let progressRepo: ProgressRepositoryProtocol

    init(container: AppContainer) {
        filmsRepo = container.filmsRepo
        progressRepo = container.progressRepo
    }

    func loadAll() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            async let f = filmsRepo.fetchFeatured()
            async let t = filmsRepo.fetchTrending()
            async let r = filmsRepo.fetchApprovedFilms()
            async let cw = progressRepo.fetchContinueWatching()
            let (feat, trend, approved, progressRows) = try await (f, t, r, cw)
            featured = feat
            trending = trend
            recentlyAdded = approved.sorted { $0.createdAt > $1.createdAt }
            continueWatchingItems = await resolveContinueWatching(progressRows, knownFilms: feat + trend + approved)
        } catch {
            featured = []
            trending = []
            recentlyAdded = []
            continueWatchingItems = []
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func resolveContinueWatching(_ rows: [FilmProgress], knownFilms: [Film]) async -> [ContinueWatchingItem] {
        let active = rows.filter { !$0.isCompleted }
        guard !active.isEmpty else { return [] }

        var filmById: [Int: Film] = [:]
        for film in knownFilms {
            filmById[film.id] = film
        }

        let missingIds = Set(active.map(\.filmId)).subtracting(filmById.keys)
        if !missingIds.isEmpty {
            await withTaskGroup(of: (Int, Film?).self) { group in
                for id in missingIds {
                    group.addTask {
                        do {
                            return (id, try await self.filmsRepo.fetchFilm(id: id))
                        } catch {
                            return (id, nil)
                        }
                    }
                }
                for await (id, film) in group {
                    if let film {
                        filmById[id] = film
                    }
                }
            }
        }

        return active.compactMap { p in
            guard let film = filmById[p.filmId] else { return nil }
            return ContinueWatchingItem(film: film, progress: p)
        }
    }
}
