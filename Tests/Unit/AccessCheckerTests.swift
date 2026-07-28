import XCTest
@testable import Filmila

private final class StubUserIdProvider: AuthSessionUserIdProviding, @unchecked Sendable {
    var userId: UUID?
    init(userId: UUID?) { self.userId = userId }
    func currentUserId() async -> UUID? { userId }
}

private final class StubUserEmailProvider: AuthSessionEmailProviding, @unchecked Sendable {
    var email: String?
    init(email: String?) { self.email = email }
    func currentUserEmail() async -> String? { email }
}

private final class StubCompletedPayments: FilmPaymentCompletedQuerying, @unchecked Sendable {
    var hasPaid = false
    func hasCompletedPayment(filmId: Int, viewerId: UUID) async throws -> Bool { hasPaid }
}

final class AccessCheckerTests: XCTestCase {
    private let viewerId = UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!

    private func paidFilm() -> Film {
        Film(
            id: 42,
            title: "Paid Film",
            price: 9.99,
            status: .approved,
            viewCount: 0,
            createdAt: Date()
        )
    }

    func testFreeFilmReturnsTrueWithoutSession() async throws {
        let checker = AccessChecker(
            userIdProvider: StubUserIdProvider(userId: nil),
            userEmailProvider: StubUserEmailProvider(email: nil),
            completedPayments: StubCompletedPayments()
        )
        let free = Film(
            id: 1,
            title: "Free",
            price: 0,
            status: .approved,
            viewCount: 0,
            createdAt: Date()
        )
        let access = try await checker.hasAccess(to: free)
        XCTAssertTrue(access)
    }

    func testCompletedPaymentReturnsTrue() async throws {
        let payments = StubCompletedPayments()
        payments.hasPaid = true
        let checker = AccessChecker(
            userIdProvider: StubUserIdProvider(userId: viewerId),
            userEmailProvider: StubUserEmailProvider(email: nil),
            completedPayments: payments
        )
        let access = try await checker.hasAccess(to: paidFilm())
        XCTAssertTrue(access)
    }

    func testNoPaymentReturnsFalseWhenSignedIn() async throws {
        let payments = StubCompletedPayments()
        payments.hasPaid = false
        let checker = AccessChecker(
            userIdProvider: StubUserIdProvider(userId: viewerId),
            userEmailProvider: StubUserEmailProvider(email: "viewer@example.com"),
            completedPayments: payments
        )
        let access = try await checker.hasAccess(to: paidFilm())
        XCTAssertFalse(access)
    }

    func testFilmmakerOwnerEmailGrantsAccessWithoutPayment() async throws {
        let payments = StubCompletedPayments()
        payments.hasPaid = false
        let checker = AccessChecker(
            userIdProvider: StubUserIdProvider(userId: viewerId),
            userEmailProvider: StubUserEmailProvider(email: "Director@Example.com"),
            completedPayments: payments
        )
        let film = Film(
            id: 99,
            title: "Own Film",
            price: 5,
            status: .approved,
            viewCount: 0,
            filmmaker: "director@example.com",
            createdAt: Date()
        )
        let access = try await checker.hasAccess(to: film)
        XCTAssertTrue(access)
    }
}
