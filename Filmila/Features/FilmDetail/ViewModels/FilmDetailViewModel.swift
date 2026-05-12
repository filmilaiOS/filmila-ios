import Foundation

enum AccessState: Equatable {
    case checking
    case free
    case purchased
    case requiresPurchase(product: Any?)
    case redirectToWeb

    static func == (lhs: AccessState, rhs: AccessState) -> Bool {
        switch (lhs, rhs) {
        case (.checking, .checking),
             (.free, .free),
             (.purchased, .purchased),
             (.redirectToWeb, .redirectToWeb):
            return true
        case (.requiresPurchase, .requiresPurchase):
            return true
        default:
            return false
        }
    }
}

@MainActor
final class FilmDetailViewModel: ObservableObject {
    @Published private(set) var film: Film?
    @Published private(set) var accessState: AccessState = .checking
    @Published private(set) var comments: [CommentDisplay] = []
    @Published private(set) var averageRating: Double = 0
    @Published private(set) var ratingCount: Int = 0
    @Published private(set) var userRating: Int?
    @Published private(set) var isInWatchlist: Bool = false
    @Published private(set) var isInFavorites: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private let filmId: Int
    private let filmsRepo: FilmsRepositoryProtocol
    private let accessChecker: AccessCheckerProtocol
    private let iapService: IAPServiceProtocol

    init(filmId: Int, container: AppContainer) {
        self.filmId = filmId
        filmsRepo = container.filmsRepo
        accessChecker = container.accessChecker
        iapService = container.iapService
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let fetched = try await filmsRepo.fetchFilm(id: filmId)
            film = fetched
        } catch {
            film = nil
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            accessState = .checking
            return
        }

        comments = (try? await filmsRepo.fetchCommentsWithAuthors(filmId: filmId)) ?? []
        if let agg = try? await filmsRepo.fetchFilmRatingsAggregate(filmId: filmId) {
            averageRating = agg.average
            ratingCount = agg.count
        } else {
            averageRating = 0
            ratingCount = 0
        }
        userRating = try? await filmsRepo.fetchUserFilmRating(filmId: filmId)
        isInWatchlist = (try? await filmsRepo.isFilmInWatchlist(filmId: filmId)) ?? false
        isInFavorites = (try? await filmsRepo.isFilmInFavorites(filmId: filmId)) ?? false

        await checkAccess()
    }

    func checkAccess() async {
        guard let film else {
            accessState = .checking
            return
        }

        accessState = .checking

        if film.isFree {
            accessState = .free
            return
        }

        do {
            if try await accessChecker.hasAccess(to: film) {
                accessState = .purchased
                return
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        do {
            if let product = try await iapService.loadProduct(filmId: filmId) {
                accessState = .requiresPurchase(product: product)
            } else {
                accessState = .redirectToWeb
            }
        } catch {
            accessState = .redirectToWeb
        }
    }

    func toggleWatchlist() async {
        guard let film else { return }
        do {
            try await filmsRepo.toggleWatchlist(filmId: film.id, add: !isInWatchlist)
            isInWatchlist.toggle()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func toggleFavorite() async {
        guard let film else { return }
        do {
            try await filmsRepo.toggleFavorite(filmId: film.id, add: !isInFavorites)
            isInFavorites.toggle()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func submitRating(_ rating: Int) async {
        guard rating >= 1, rating <= 5 else { return }
        do {
            try await filmsRepo.upsertUserFilmRating(filmId: filmId, rating: rating)
            userRating = rating
            if let agg = try? await filmsRepo.fetchFilmRatingsAggregate(filmId: filmId) {
                averageRating = agg.average
                ratingCount = agg.count
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func submitComment(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            try await filmsRepo.insertComment(filmId: filmId, text: trimmed)
            comments = (try? await filmsRepo.fetchCommentsWithAuthors(filmId: filmId)) ?? comments
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func setErrorMessage(_ message: String?) {
        errorMessage = message
    }
}
