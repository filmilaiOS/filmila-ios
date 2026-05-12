import Foundation

struct InboxNotification: Identifiable, Decodable, Equatable {
    let id: UUID
    let userId: UUID
    let title: String
    let body: String?
    let createdAt: Date
    var isRead: Bool
    let iconName: String?

    init(id: UUID, userId: UUID, title: String, body: String?, createdAt: Date, isRead: Bool, iconName: String?) {
        self.id = id
        self.userId = userId
        self.title = title
        self.body = body
        self.createdAt = createdAt
        self.isRead = isRead
        self.iconName = iconName
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case body
        case createdAt = "created_at"
        case isRead = "is_read"
        case iconName = "icon_name"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decodeIfPresent(String.self, forKey: .body)
        createdAt = try container.decodeFilmilaTimestamp(forKey: .createdAt)
        isRead = try container.decodeIfPresent(Bool.self, forKey: .isRead) ?? false
        iconName = try container.decodeIfPresent(String.self, forKey: .iconName)
    }
}
