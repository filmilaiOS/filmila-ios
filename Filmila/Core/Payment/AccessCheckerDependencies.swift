import Foundation
import Supabase

// MARK: - Session + payment queries (injectable for tests)

protocol AuthSessionUserIdProviding: Sendable {
    func currentUserId() async -> UUID?
}

protocol AuthSessionEmailProviding: Sendable {
    func currentUserEmail() async -> String?
}

protocol FilmPaymentCompletedQuerying: Sendable {
    func hasCompletedPayment(filmId: Int, viewerId: UUID) async throws -> Bool
}

final class SupabaseAuthSessionUserIdProvider: AuthSessionUserIdProviding, @unchecked Sendable {
    private var client: SupabaseClient { SupabaseManager.shared.client }

    func currentUserId() async -> UUID? {
        (try? await client.auth.session)?.user.id
    }
}

final class SupabaseAuthSessionEmailProvider: AuthSessionEmailProviding, @unchecked Sendable {
    private var client: SupabaseClient { SupabaseManager.shared.client }

    func currentUserEmail() async -> String? {
        (try? await client.auth.session)?.user.email
    }
}

private struct FilmPaymentIdRow: Decodable {
    let id: UUID
}

final class SupabaseFilmPaymentCompletedQuery: FilmPaymentCompletedQuerying, @unchecked Sendable {
    private var client: SupabaseClient { SupabaseManager.shared.client }

    func hasCompletedPayment(filmId: Int, viewerId: UUID) async throws -> Bool {
        let rows: [FilmPaymentIdRow] = try await client
            .from("film_payments")
            .select("id")
            .eq("film_id", value: filmId)
            .eq("viewer_id", value: viewerId.uuidString)
            .eq("status", value: "completed")
            .limit(1)
            .execute()
            .value
        return !rows.isEmpty
    }
}
