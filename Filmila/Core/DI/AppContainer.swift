import Foundation

// defined in respective file
protocol UserRepositoryProtocol: Sendable {}

// defined in respective file (see IAPService.swift)

protocol AppContainer: AnyObject {
    var authService: AuthServiceProtocol { get }
    var filmsRepo: FilmsRepositoryProtocol { get }
    var progressRepo: ProgressRepositoryProtocol { get }
    var userRepo: UserRepositoryProtocol { get }
    var iapService: IAPServiceProtocol { get }
    var accessChecker: AccessCheckerProtocol { get }
    var s3Service: S3SignedURLServiceProtocol { get }
    var networkMonitor: any NetworkMonitorProtocol { get }
    var deepLinkHandler: DeepLinkHandler { get }
    var notificationsRepo: NotificationsRepositoryProtocol { get }
}
