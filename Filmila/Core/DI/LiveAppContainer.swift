import Foundation

final class LiveAppContainer: AppContainer {
    let auth: AuthService
    let pathMonitor: NetworkMonitor
    let deepLinkHandler = DeepLinkHandler()

    private lazy var filmsRepository = LiveFilmsRepository()
    private let notificationsRepository = LiveNotificationsRepository()

    init() {
        auth = AuthService()
        pathMonitor = NetworkMonitor()
    }

    var authService: AuthServiceProtocol { auth }
    var filmsRepo: FilmsRepositoryProtocol { filmsRepository }
    lazy var progressRepo: ProgressRepositoryProtocol = LiveProgressRepository()
    private lazy var userRepository = LiveUserRepository()
    lazy var userRepo: UserRepositoryProtocol = userRepository
    lazy var iapService: IAPServiceProtocol = IAPService()
    lazy var accessChecker: AccessCheckerProtocol = AccessChecker()
    lazy var s3Service: S3SignedURLServiceProtocol = S3SignedURLService()
    var networkMonitor: any NetworkMonitorProtocol { pathMonitor }
    var notificationsRepo: NotificationsRepositoryProtocol { notificationsRepository }
}
