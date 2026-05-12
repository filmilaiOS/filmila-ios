import Foundation

struct AppNotification: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let userId: UUID
    let type: String
    let title: String
    let body: String?
    let filmId: Int?
    let isRead: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type
        case title
        case body
        case filmId = "film_id"
        case isRead = "is_read"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        type = try container.decode(String.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decodeIfPresent(String.self, forKey: .body)
        filmId = try container.decodeIfPresent(Int.self, forKey: .filmId)
        isRead = try container.decode(Bool.self, forKey: .isRead)
        createdAt = try container.decodeFilmilaTimestamp(forKey: .createdAt)
    }
}
