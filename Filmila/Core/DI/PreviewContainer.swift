import Combine
import Foundation
import Supabase
import SwiftUI

// MARK: - Sample data

enum PreviewFilmSamples {
    static let films: [Film] = [
        Film(
            id: 1,
            title: "Desert Light",
            description: "Stories told beneath an open sky.",
            thumbnailUrl: "https://picsum.photos/seed/filmila1/800/1200",
            price: 0,
            status: .approved,
            genre: "Drama",
            duration: 7_200,
            viewCount: 1_200,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        ),
        Film(
            id: 2,
            title: "City Echoes",
            description: "Neon nights and quiet corners.",
            thumbnailUrl: "https://picsum.photos/seed/filmila2/800/1200",
            price: 19,
            status: .approved,
            genre: "Thriller",
            duration: 5_400,
            viewCount: 980,
            createdAt: Date(timeIntervalSince1970: 1_710_000_000)
        ),
        Film(
            id: 3,
            title: "Coastal Road",
            description: "One journey. Three strangers.",
            thumbnailUrl: "https://picsum.photos/seed/filmila3/800/1200",
            price: 24.5,
            status: .approved,
            genre: "Road",
            duration: 6_000,
            viewCount: 760,
            createdAt: Date(timeIntervalSince1970: 1_720_000_000)
        ),
        Film(
            id: 99,
            title: "Pending Cut",
            description: "Should never appear in approved-only lists.",
            thumbnailUrl: nil,
            price: 5,
            status: .pending,
            genre: "Drama",
            duration: 100,
            viewCount: 0,
            createdAt: Date()
        )
    ]
}

// MARK: - Mock services

private final class PreviewAuthService: AuthServiceProtocol {
    private(set) var session: Session?
    private(set) var profile: Profile?
    private(set) var isLoading: Bool = false

    var currentToken: String? { nil }
    var userEmail: String? { "preview@filmila.com" }

    func login(email: String, password: String) async throws {}

    func register(email: String, password: String, fullName: String) async throws {}

    func restoreSession() async {}

    func signOut() async throws {}
}

private final class PreviewFilmsRepository: FilmsRepositoryProtocol {
    private var watchlistIds: Set<Int> = [1]
    private var favoriteIds: Set<Int> = [2]
    private var userRatingByFilm: [Int: Int] = [:]

    func fetchApprovedFilms() async throws -> [Film] {
        FilmsApprovedCatalogPolicy.filterApprovedOnly(PreviewFilmSamples.films).sorted { $0.createdAt > $1.createdAt }
    }

    func fetchFilm(id: Int) async throws -> Film {
        guard let film = PreviewFilmSamples.films.first(where: { $0.id == id }) else {
            throw FilmsRepositoryError.filmNotFound
        }
        return film
    }

    func fetchFilmmakerProfile(filmmakerEmail: String) async throws -> FilmmakerProfile? {
        FilmmakerProfile(
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000D1")!,
            displayName: "Preview Director",
            avatarUrl: "https://picsum.photos/seed/preview-director/200/200",
            bio: "Short films with bold visual storytelling.",
            location: "Riyadh",
            email: "preview@filmila.com"
        )
    }

    func fetchFilmmakerProfile(directorId: UUID) async throws -> FilmmakerProfile? {
        try await fetchFilmmakerProfile(filmmakerEmail: "preview@filmila.com")
    }

    func fetchApprovedFilms(filmmakerEmail: String) async throws -> [Film] {
        try await fetchApprovedFilms()
    }

    func searchFilms(query: String, genre: String?) async throws -> [Film] {
        try await fetchApprovedFilms()
    }

    func fetchFeatured() async throws -> [Film] {
        Array(try await fetchApprovedFilms().prefix(3))
    }

    func fetchTrending() async throws -> [Film] {
        try await fetchApprovedFilms().sorted { $0.viewCount > $1.viewCount }
    }

    func toggleWatchlist(filmId: Int, add: Bool) async throws {
        if add { watchlistIds.insert(filmId) } else { watchlistIds.remove(filmId) }
    }

    func toggleFavorite(filmId: Int, add: Bool) async throws {
        if add { favoriteIds.insert(filmId) } else { favoriteIds.remove(filmId) }
    }

    func fetchWatchlist() async throws -> [Film] {
        filmsForIds(Array(watchlistIds))
    }

    func fetchFavorites() async throws -> [Film] {
        filmsForIds(Array(favoriteIds))
    }

    func fetchPurchaseHistory() async throws -> [FilmPayment] {
        let viewer = UUID(uuidString: "00000000-0000-0000-0000-000000000099")!
        return [
            FilmPayment(
                id: UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!,
                filmId: 2,
                viewerId: viewer,
                status: .completed,
                paymentMethod: "iap",
                amount: 19,
                paymentId: "mock_tx_1",
                createdAt: Date().addingTimeInterval(-86400)
            )
        ]
    }

    func fetchFilms(byIds ids: [Int]) async throws -> [Film] {
        filmsForIds(Array(Set(ids)))
    }

    private func filmsForIds(_ ids: [Int]) -> [Film] {
        ids.compactMap { id in PreviewFilmSamples.films.first(where: { $0.id == id }) }
    }

    func fetchCommentsWithAuthors(filmId: Int) async throws -> [CommentDisplay] {
        [
            CommentDisplay(
                id: UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!,
                filmId: filmId,
                userId: UUID(uuidString: "00000000-0000-0000-0000-0000000000BB")!,
                content: String(localized: "mock_comment_body"),
                createdAt: Date().addingTimeInterval(-3600),
                authorDisplayName: "Preview"
            )
        ]
    }

    func fetchFilmRatingsAggregate(filmId: Int) async throws -> (average: Double, count: Int) {
        (4.2, 12)
    }

    func fetchAverageRatings(forFilmIds ids: [Int]) async throws -> [Int: Double] {
        let unique = Array(Set(ids))
        return Dictionary(uniqueKeysWithValues: unique.map { id in
            (id, 3.5 + Double(id % 5) * 0.1)
        })
    }

    func fetchUserFilmRating(filmId: Int) async throws -> Int? {
        userRatingByFilm[filmId]
    }

    func upsertUserFilmRating(filmId: Int, rating: Int) async throws {
        userRatingByFilm[filmId] = rating
    }

    func insertComment(filmId: Int, text: String) async throws {}

    func isFilmInWatchlist(filmId: Int) async throws -> Bool {
        watchlistIds.contains(filmId)
    }

    func isFilmInFavorites(filmId: Int) async throws -> Bool {
        favoriteIds.contains(filmId)
    }
}

private final class PreviewIAPService: IAPServiceProtocol {
    func loadProduct(filmId: Int) async throws -> Any? { nil }

    func purchase(filmId: Int) async throws -> PurchaseOutcome {
        .success
    }

    func restorePurchases() async throws {}

    func hasPurchased(filmId: Int) async -> Bool { false }
}

private final class PreviewProgressRepository: ProgressRepositoryProtocol {
    func saveProgress(filmId: Int, seconds: Int) async throws {}
    func fetchProgress(filmId: Int) async throws -> FilmProgress? { nil }

    func fetchContinueWatching() async throws -> [FilmProgress] {
        [
            FilmProgress(
                userId: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                filmId: 1,
                progressSeconds: 900
            ),
            FilmProgress(
                userId: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                filmId: 2,
                progressSeconds: 120
            )
        ]
    }
}

private final class PreviewAccessChecker: AccessCheckerProtocol {
    func hasAccess(to film: Film) async throws -> Bool {
        film.isFree || film.id == 1
    }
}

private struct PreviewUserRepository: UserRepositoryProtocol {}

private final class PreviewS3SignedURLService: S3SignedURLServiceProtocol {
    func fetchPlaybackURL(filmId: Int) async throws -> URL {
        URL(string: "https://example.com/playback")!
    }

    func invalidateCache(filmId: Int) {}
}

private final class PreviewNetworkMonitor: NetworkMonitorProtocol {
    @Published private(set) var isConnected: Bool = true
}

private final class PreviewNotificationsRepository: NotificationsRepositoryProtocol {
    private let previewUserId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    func fetchNotifications() async throws -> [InboxNotification] {
        [
            InboxNotification(
                id: UUID(uuidString: "00000000-0000-0000-0000-0000000000C1")!,
                userId: previewUserId,
                title: String(localized: "notifications_title"),
                body: String(localized: "landing_tagline"),
                createdAt: Date().addingTimeInterval(-120),
                isRead: false,
                iconName: "bell.fill"
            ),
            InboxNotification(
                id: UUID(uuidString: "00000000-0000-0000-0000-0000000000C2")!,
                userId: previewUserId,
                title: String(localized: "library_title"),
                body: nil,
                createdAt: Date().addingTimeInterval(-9000),
                isRead: true,
                iconName: "film.fill"
            )
        ]
    }

    func markRead(notificationId: UUID) async throws {}
}

private final class PreviewForumRepository: ForumRepositoryProtocol {
    private let categories: [ForumCategory] = [
        ForumCategory(id: 1, name: "General", color: "#EF4444"),
        ForumCategory(id: 2, name: "Filmmaking", color: "#8B5CF6"),
        ForumCategory(id: 3, name: "Film Ideas", color: "#0891B2")
    ]

    private let posts: [ForumPost] = [
        ForumPost(
            id: 1,
            title: "Best indie films this year?",
            content: "What are you watching lately?",
            authorDisplayName: "Sara",
            likeCount: 12,
            commentCount: 4,
            createdAt: Date().addingTimeInterval(-86_400),
            categoryId: 1,
            category: ForumCategory(id: 1, name: "General")
        ),
        ForumPost(
            id: 2,
            title: "Hidden gem: Coastal Road",
            content: "Highly recommend this one.",
            authorDisplayName: "Omar",
            likeCount: 8,
            commentCount: 2,
            createdAt: Date().addingTimeInterval(-172_800),
            categoryId: 2,
            category: ForumCategory(id: 2, name: "Filmmaking")
        )
    ]

    private let comments: [ForumComment] = [
        ForumComment(
            id: 1,
            postId: 1,
            content: "I loved Desert Light.",
            authorDisplayName: "Jamila",
            createdAt: Date().addingTimeInterval(-43_200)
        ),
        ForumComment(
            id: 2,
            postId: 1,
            content: "City Echoes was great too.",
            authorDisplayName: "Alex",
            createdAt: Date().addingTimeInterval(-21_600)
        )
    ]

    func fetchCategories() async throws -> [ForumCategory] { categories }

    func fetchPosts(categoryId: Int?) async throws -> [ForumPost] {
        guard let categoryId else { return posts }
        return posts.filter { $0.categoryId == categoryId }
    }

    func fetchPost(id: Int) async throws -> ForumPost {
        guard let post = posts.first(where: { $0.id == id }) else {
            throw ForumRepositoryError.postNotFound
        }
        return post
    }

    func fetchComments(postId: Int) async throws -> [ForumComment] {
        comments.filter { $0.postId == postId }
    }
}

// MARK: - Container

/// SwiftUI previews and canvas: deterministic mocks for every `AppContainer` dependency.
final class PreviewContainer: AppContainer {
    private let previewAuth = PreviewAuthService()
    private let previewFilms = PreviewFilmsRepository()
    private let previewProgress = PreviewProgressRepository()
    private let previewAccess = PreviewAccessChecker()
    private let previewS3 = PreviewS3SignedURLService()
    private let previewIAP = PreviewIAPService()
    private let previewNetwork = PreviewNetworkMonitor()
    private let previewNotifications = PreviewNotificationsRepository()
    private let previewForum = PreviewForumRepository()
    let deepLinkHandler = DeepLinkHandler()

    /// Real `NetworkMonitor` for `MainTabView` / banners (lightweight; uses `NWPathMonitor`).
    let pathMonitor = NetworkMonitor()

    var authService: AuthServiceProtocol { previewAuth }
    var filmsRepo: FilmsRepositoryProtocol { previewFilms }
    var progressRepo: ProgressRepositoryProtocol { previewProgress }
    var userRepo: UserRepositoryProtocol { PreviewUserRepository() }
    var iapService: IAPServiceProtocol { previewIAP }
    var accessChecker: AccessCheckerProtocol { previewAccess }
    var s3Service: S3SignedURLServiceProtocol { previewS3 }
    var networkMonitor: any NetworkMonitorProtocol { previewNetwork }
    var notificationsRepo: NotificationsRepositoryProtocol { previewNotifications }
    var forumRepo: ForumRepositoryProtocol { previewForum }
}

// MARK: - Auth + environment helpers (Xcode previews)

extension PreviewContainer {
    /// Configures a real `AuthService` with preview-only state (no Supabase session required).
    @MainActor
    static func makeSignedInAuthForPreviews() -> AuthService {
        let auth = AuthService()
        let profile = Profile(
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000D1")!,
            role: "VIEWER",
            fullName: "Jamila",
            avatarUrl: "https://picsum.photos/seed/avatar/400/400",
            apnsToken: nil
        )
        auth.applyPreviewSignedInState(userEmail: "jamila@example.com", profile: profile)
        return auth
    }
}

extension View {
    /// Standard preview wiring: mock `AppContainer`, tab bar `NetworkMonitor`, and signed-in `AuthService`.
    func filmilaPreviewChrome() -> some View {
        let container = PreviewContainer()
        let auth = PreviewContainer.makeSignedInAuthForPreviews()
        return environment(\.container, container)
            .environmentObject(auth)
            .environmentObject(container.pathMonitor)
            .environmentObject(container.deepLinkHandler)
            .preferredColorScheme(.dark)
    }
}

/// Legacy alias — use `PreviewContainer` in new code.
typealias MockAppContainer = PreviewContainer
