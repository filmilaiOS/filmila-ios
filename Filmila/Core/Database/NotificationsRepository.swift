import Foundation
import Supabase

protocol NotificationsRepositoryProtocol: AnyObject {
    func fetchNotifications() async throws -> [InboxNotification]
    func markRead(notificationId: UUID) async throws
}

final class LiveNotificationsRepository: NotificationsRepositoryProtocol {
    private var client: SupabaseClient { SupabaseManager.shared.client }

    private func currentUserId() async throws -> UUID {
        try await client.auth.session.user.id
    }

    func fetchNotifications() async throws -> [InboxNotification] {
        let userId = try await currentUserId()
        return try await client.from("notifications")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func markRead(notificationId: UUID) async throws {
        try await client.from("notifications")
            .update(["is_read": AnyJSON.bool(true)])
            .eq("id", value: notificationId.uuidString)
            .execute()
    }
}
