import Foundation

struct FilmRating: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let filmId: Int
    let userId: UUID
    let rating: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case filmId = "film_id"
        case userId = "user_id"
        case rating
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        filmId = try container.decode(Int.self, forKey: .filmId)
        userId = try container.decode(UUID.self, forKey: .userId)
        rating = try container.decode(Int.self, forKey: .rating)
        createdAt = try container.decodeFilmilaTimestamp(forKey: .createdAt)
    }
}
