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

struct WebCheckoutItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL
}

@MainActor
final class FilmDetailViewModel: ObservableObject {
    @Published private(set) var film: Film?
    @Published private(set) var accessState: AccessState = .checking
    @Published private(set) var comments: [CommentDisplay] = []
    @Published private(set) var averageRating: Double = 0
    @Published private(set) var ratingCount: Int = 0
    @Published private(set) var userRating: Int?
    @Published private(set) var ratingFeedbackMessage: String?
    @Published private(set) var filmmakerProfile: FilmmakerProfile?
    @Published private(set) var isInWatchlist: Bool = false
    @Published private(set) var isInFavorites: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var isAwaitingWebPurchaseReturn = false
    @Published private(set) var purchaseNotice: String?
    @Published var webCheckout: WebCheckoutItem?

    private let filmId: Int
    private let filmsRepo: FilmsRepositoryProtocol
    private let accessChecker: AccessCheckerProtocol
    private let iapService: IAPServiceProtocol
    private let authService: AuthServiceProtocol

    init(filmId: Int, container: AppContainer) {
        self.filmId = filmId
        filmsRepo = container.filmsRepo
        accessChecker = container.accessChecker
        iapService = container.iapService
        authService = container.authService
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

        if let email = film?.filmmaker?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty {
            filmmakerProfile = try? await filmsRepo.fetchFilmmakerProfile(filmmakerEmail: email)
        } else {
            filmmakerProfile = nil
        }

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

    func startWebPurchase() {
        guard let film, !film.isFree else { return }
        purchaseNotice = nil
        guard let token = authService.currentToken, !token.isEmpty else {
            errorMessage = String(localized: "geidea_payment_not_signed_in")
            return
        }
        guard let url = FilmWebPurchaseURL.purchaseURL(forFilmId: film.id, accessToken: token) else { return }
        markWebPurchaseStarted()
        webCheckout = WebCheckoutItem(url: url)
    }

    func completeWebCheckoutFlow() async {
        webCheckout = nil
        await recheckAccessAfterWebPurchase()
    }

    func handlePaymentCompleteDeepLink(filmId: Int?) async {
        guard isAwaitingWebPurchaseReturn else { return }
        if let filmId, filmId != self.filmId { return }
        await completeWebCheckoutFlow()
    }

    func handlePaymentCancelledDeepLink(filmId: Int?) async {
        guard isAwaitingWebPurchaseReturn else { return }
        if let filmId, filmId != self.filmId { return }
        webCheckout = nil
        isAwaitingWebPurchaseReturn = false
        purchaseNotice = String(localized: "detail_purchase_cancelled")
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        purchaseNotice = nil
    }

    func markWebPurchaseStarted() {
        isAwaitingWebPurchaseReturn = true
    }

    func recheckAccessAfterWebPurchase() async {
        guard isAwaitingWebPurchaseReturn else { return }
        await checkAccess()
        if case .purchased = accessState {
            isAwaitingWebPurchaseReturn = false
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
            if averageRating > 0 {
                ratingFeedbackMessage = String(
                    format: String(localized: "detail_rating_thanks_average_format"),
                    Film.formattedAverageRating(averageRating)
                )
            } else {
                ratingFeedbackMessage = String(
                    format: String(localized: "detail_rating_your_stars_format"),
                    rating
                )
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func clearRatingFeedbackMessage() {
        ratingFeedbackMessage = nil
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
