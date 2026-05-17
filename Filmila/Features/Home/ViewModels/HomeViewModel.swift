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
    @Published private(set) var averageRatingByFilmId: [Int: Double] = [:]
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

        let feat: [Film]
        let trend: [Film]
        let approved: [Film]
        do {
            async let f = filmsRepo.fetchFeatured()
            async let t = filmsRepo.fetchTrending()
            async let r = filmsRepo.fetchApprovedFilms()
            (feat, trend, approved) = try await (f, t, r)
        } catch is CancellationError {
            return
        } catch {
#if DEBUG
            print("[HomeViewModel] film catalog load failed: \(error)")
#endif
            featured = []
            trending = []
            recentlyAdded = []
            continueWatchingItems = []
            averageRatingByFilmId = [:]
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return
        }

        let progressRows: [FilmProgress]
        do {
            progressRows = try await progressRepo.fetchContinueWatching()
        } catch {
#if DEBUG
            print("[HomeViewModel] continue watching unavailable (ignored): \(error)")
#endif
            progressRows = []
        }

        featured = feat
        trending = trend
        recentlyAdded = approved.sorted { $0.createdAt > $1.createdAt }
        continueWatchingItems = await resolveContinueWatching(progressRows, knownFilms: feat + trend + approved)

        let ratingIds = Array(
            Set(feat.map(\.id) + trend.map(\.id) + recentlyAdded.map(\.id) + continueWatchingItems.map(\.film.id))
        )
        if ratingIds.isEmpty {
            averageRatingByFilmId = [:]
        } else {
            averageRatingByFilmId = (try? await filmsRepo.fetchAverageRatings(forFilmIds: ratingIds)) ?? [:]
        }
        error = nil
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
