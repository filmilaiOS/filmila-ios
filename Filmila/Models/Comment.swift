import Foundation

struct Comment: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let filmId: Int
    let userId: UUID
    let content: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case filmId = "film_id"
        case userId = "user_id"
        case content
        case createdAt = "created_at"
    }

    init(id: UUID, filmId: Int, userId: UUID, content: String, createdAt: Date) {
        self.id = id
        self.filmId = filmId
        self.userId = userId
        self.content = content
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        filmId = try container.decode(Int.self, forKey: .filmId)
        userId = try container.decode(UUID.self, forKey: .userId)
        content = try container.decode(String.self, forKey: .content)
        createdAt = try container.decodeFilmilaTimestamp(forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(filmId, forKey: .filmId)
        try container.encode(userId, forKey: .userId)
        try container.encode(content, forKey: .content)
        try container.encode(createdAt, forKey: .createdAt)
    }
}
