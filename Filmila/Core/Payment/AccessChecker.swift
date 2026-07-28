import Foundation

protocol AccessCheckerProtocol: AnyObject {
    func hasAccess(to film: Film) async throws -> Bool
}

final class AccessChecker: AccessCheckerProtocol {
    private let userIdProvider: AuthSessionUserIdProviding
    private let userEmailProvider: AuthSessionEmailProviding
    private let completedPayments: FilmPaymentCompletedQuerying

    init(
        userIdProvider: AuthSessionUserIdProviding = SupabaseAuthSessionUserIdProvider(),
        userEmailProvider: AuthSessionEmailProviding = SupabaseAuthSessionEmailProvider(),
        completedPayments: FilmPaymentCompletedQuerying = SupabaseFilmPaymentCompletedQuery()
    ) {
        self.userIdProvider = userIdProvider
        self.userEmailProvider = userEmailProvider
        self.completedPayments = completedPayments
    }

    func hasAccess(to film: Film) async throws -> Bool {
        if film.isFree {
            return true
        }
        if Self.isFilmmakerOwner(film: film, userEmail: await userEmailProvider.currentUserEmail()) {
            return true
        }
        guard let viewerId = await userIdProvider.currentUserId() else {
            return false
        }
        return try await completedPayments.hasCompletedPayment(filmId: film.id, viewerId: viewerId)
    }

    /// Grants watch access when the signed-in account matches the film's `filmmaker` email.
    static func isFilmmakerOwner(film: Film, userEmail: String?) -> Bool {
        guard let filmmaker = film.filmmaker?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !filmmaker.isEmpty,
              let email = userEmail?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !email.isEmpty
        else { return false }
        return email == filmmaker
    }
}
