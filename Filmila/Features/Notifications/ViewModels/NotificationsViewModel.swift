import Foundation

@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published private(set) var items: [InboxNotification] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let repo: NotificationsRepositoryProtocol

    init(container: AppContainer) {
        repo = container.notificationsRepo
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            items = try await repo.fetchNotifications()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            items = []
        }
    }

    func markRead(_ notification: InboxNotification) async {
        guard !notification.isRead else { return }
        if let idx = items.firstIndex(where: { $0.id == notification.id }) {
            var updated = items[idx]
            updated.isRead = true
            items[idx] = updated
        }
        do {
            try await repo.markRead(notificationId: notification.id)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            await load()
        }
    }
}
