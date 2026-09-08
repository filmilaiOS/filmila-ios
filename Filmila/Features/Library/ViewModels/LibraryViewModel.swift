import Foundation

enum LibraryTab: String, CaseIterable, Identifiable {
    case watchlist
    case favorites
    case purchases

    var id: String { rawValue }
}

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published private(set) var watchlist: [Film] = []
    @Published private(set) var favorites: [Film] = []
    @Published private(set) var purchaseHistory: [FilmPayment] = []
    /// Films for purchased titles (order follows first occurrence in `purchaseHistory`).
    @Published private(set) var purchasedFilms: [Film] = []
    @Published var selectedTab: LibraryTab = .watchlist
    @Published private(set) var isLoading = false

    private let filmsRepo: FilmsRepositoryProtocol

    init(container: AppContainer) {
        filmsRepo = container.filmsRepo
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let wl = filmsRepo.fetchWatchlist()
            async let fav = filmsRepo.fetchFavorites()
            async let pay = filmsRepo.fetchPurchaseHistory()
            let (w, f, payments) = try await (wl, fav, pay)
            watchlist = w
            favorites = f
            // Match AccessChecker: only `film_payments.status == completed` counts as a purchase.
            let completedPayments = payments.filter { $0.status == .completed }
            purchaseHistory = completedPayments

            let orderedUniqueFilmIds = completedPayments.map(\.filmId).reduce(into: [Int]()) { acc, id in
                if !acc.contains(id) {
                    acc.append(id)
                }
            }
            let films = try await filmsRepo.fetchFilms(byIds: orderedUniqueFilmIds)
            let byId = Dictionary(uniqueKeysWithValues: films.map { ($0.id, $0) })
            purchasedFilms = orderedUniqueFilmIds.compactMap { byId[$0] }
        } catch {
            watchlist = []
            favorites = []
            purchaseHistory = []
            purchasedFilms = []
        }
    }
}
