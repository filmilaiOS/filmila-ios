import Foundation

struct FilmProgress: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let userId: UUID
    let filmId: Int
    let progressSeconds: Int
    let completedAt: Date?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "viewer_id"
        case filmId = "film_id"
        case progressSeconds = "progress_seconds"
        case completedAt = "completed_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID = UUID(),
        userId: UUID,
        filmId: Int,
        progressSeconds: Int,
        completedAt: Date? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.filmId = filmId
        self.progressSeconds = progressSeconds
        self.completedAt = completedAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        filmId = try container.decode(Int.self, forKey: .filmId)
        progressSeconds = try container.decode(Int.self, forKey: .progressSeconds)
        completedAt = try container.decodeFilmilaTimestampIfPresent(forKey: .completedAt)
        updatedAt = try container.decodeFilmilaTimestamp(forKey: .updatedAt)
    }

    var isCompleted: Bool {
        completedAt != nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(filmId, forKey: .filmId)
        try container.encode(progressSeconds, forKey: .progressSeconds)
        try container.encodeIfPresent(completedAt, forKey: .completedAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
