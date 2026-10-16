import Foundation
import Supabase

struct ForumBlockedUser: Identifiable {
    let id: UUID
    let displayName: String
}

enum ForumSafetyError: LocalizedError {
    case signInRequired
    case cannotBlockSelf

    var errorDescription: String? {
        switch self {
        case .signInRequired: return String(localized: "safety_sign_in_required")
        case .cannotBlockSelf: return String(localized: "safety_cannot_block_self")
        }
    }
}

/// Uses the same RLS-protected moderation tables as Filmila Hub on the web.
final class ForumSafetyService {
    static let shared = ForumSafetyService()
    private var client: SupabaseClient { SupabaseManager.shared.client }

    private func userId() async throws -> UUID {
        do { return try await client.auth.session.user.id }
        catch { throw ForumSafetyError.signInRequired }
    }

    func blockedIds() async throws -> Set<UUID> {
        let user = try await userId()
        struct Row: Decodable { let blocked_id: UUID }
        let rows: [Row] = try await client.from("forum_user_blocks")
            .select("blocked_id")
            .eq("blocker_id", value: user.uuidString)
            .execute().value
        return Set(rows.map(\.blocked_id))
    }

    func blockedUsers() async throws -> [ForumBlockedUser] {
        let ids = try await blockedIds()
        guard !ids.isEmpty else { return [] }
        struct ProfileRow: Decodable {
            let id: UUID
            let display_name: String?
            let full_name: String?
        }
        let rows: [ProfileRow] = try await client.from("profiles")
            .select("id,display_name,full_name")
            .in("id", values: ids.map(\.uuidString))
            .execute().value
        let names = Dictionary(uniqueKeysWithValues: rows.map {
            ($0.id, $0.display_name ?? $0.full_name ?? String(localized: "safety_unknown_user"))
        })
        return ids.sorted { $0.uuidString < $1.uuidString }.map {
            ForumBlockedUser(id: $0, displayName: names[$0] ?? String(localized: "safety_unknown_user"))
        }
    }

    func block(_ authorId: UUID) async throws {
        let user = try await userId()
        guard user != authorId else { throw ForumSafetyError.cannotBlockSelf }
        struct Row: Encodable { let blocker_id: UUID; let blocked_id: UUID }
        do {
            try await client.from("forum_user_blocks")
                .insert(Row(blocker_id: user, blocked_id: authorId)).execute()
        } catch {
            // Duplicate blocks are already successful; do not suppress other errors.
            if !String(describing: error).contains("23505") { throw error }
        }
    }

    func unblock(_ authorId: UUID) async throws {
        let user = try await userId()
        try await client.from("forum_user_blocks")
            .delete()
            .eq("blocker_id", value: user.uuidString)
            .eq("blocked_id", value: authorId.uuidString)
            .execute()
    }

    func report(postId: Int? = nil, commentId: Int? = nil, reason: String) async throws {
        let user = try await userId()
        struct Report: Encodable {
            let reporter_id: UUID
            let post_id: Int?
            let comment_id: Int?
            let reason: String
        }
        try await client.from("forum_reports").insert(
            Report(reporter_id: user, post_id: postId, comment_id: commentId, reason: reason)
        ).execute()
    }
}
