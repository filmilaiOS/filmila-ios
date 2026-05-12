import Foundation

protocol AccessCheckerProtocol: AnyObject {
    func hasAccess(to film: Film) async throws -> Bool
}

final class AccessChecker: AccessCheckerProtocol {
    private let userIdProvider: AuthSessionUserIdProviding
    private let completedPayments: FilmPaymentCompletedQuerying

    init(
        userIdProvider: AuthSessionUserIdProviding = SupabaseAuthSessionUserIdProvider(),
        completedPayments: FilmPaymentCompletedQuerying = SupabaseFilmPaymentCompletedQuery()
    ) {
        self.userIdProvider = userIdProvider
        self.completedPayments = completedPayments
    }

    func hasAccess(to film: Film) async throws -> Bool {
        if film.isFree {
            return true
        }
        guard let viewerId = await userIdProvider.currentUserId() else {
            return false
        }
        return try await completedPayments.hasCompletedPayment(filmId: film.id, viewerId: viewerId)
    }
}
