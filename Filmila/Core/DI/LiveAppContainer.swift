import Foundation

final class LiveAppContainer: AppContainer {
    /// Lazily created once; `authService` and `FilmilaApp`’s `@StateObject` must use this same instance.
    lazy var sharedAuthService: AuthService = AuthService()
    var authService: AuthServiceProtocol { sharedAuthService }
    let pathMonitor: NetworkMonitor
    let deepLinkHandler = DeepLinkHandler()

    private lazy var filmsRepository = LiveFilmsRepository()
    private let notificationsRepository = LiveNotificationsRepository()
    private lazy var forumRepository = LiveForumRepository()

    init() {
        pathMonitor = NetworkMonitor()
    }
    var filmsRepo: FilmsRepositoryProtocol { filmsRepository }
    lazy var progressRepo: ProgressRepositoryProtocol = LiveProgressRepository()
    private lazy var userRepository = LiveUserRepository()
    lazy var userRepo: UserRepositoryProtocol = userRepository
    lazy var iapService: IAPServiceProtocol = IAPService()
    lazy var accessChecker: AccessCheckerProtocol = AccessChecker()
    lazy var s3Service: S3SignedURLServiceProtocol = S3SignedURLService()
    var networkMonitor: any NetworkMonitorProtocol { pathMonitor }
    var notificationsRepo: NotificationsRepositoryProtocol { notificationsRepository }
    var forumRepo: ForumRepositoryProtocol { forumRepository }
}
