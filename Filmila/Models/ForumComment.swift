import Foundation

struct ForumComment: Identifiable, Codable, Equatable {
    let id: Int
    let postId: Int
    let content: String
    let authorDisplayName: String?
    let authorId: UUID?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case content
        case authorDisplayName = "author_display_name"
        case authorId = "author_id"
        case createdAt = "created_at"
    }

    init(
        id: Int,
        postId: Int,
        content: String,
        authorDisplayName: String? = nil,
        authorId: UUID? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.postId = postId
        self.content = content
        self.authorDisplayName = authorDisplayName
        self.authorId = authorId
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        postId = try container.decode(Int.self, forKey: .postId)
        content = try container.decode(String.self, forKey: .content)
        authorDisplayName = try container.decodeIfPresent(String.self, forKey: .authorDisplayName)
        authorId = try container.decodeIfPresent(UUID.self, forKey: .authorId)
        createdAt = try container.decodeFilmilaTimestampIfPresent(forKey: .createdAt)
    }

    var displayAuthorName: String {
        let trimmed = authorDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? String(localized: "community_author_anonymous") : trimmed
    }
}
