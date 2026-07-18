import Foundation

struct ForumPost: Identifiable, Codable, Equatable {
    let id: Int
    let title: String
    let content: String?
    let imageUrl: String?
    let authorDisplayName: String?
    let authorId: UUID?
    let likeCount: Int?
    let commentCount: Int?
    let createdAt: Date?

    let categoryId: Int?
    let forumCategories: ForumCategory?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case imageUrl = "image_url"
        case authorDisplayName = "author_display_name"
        case authorId = "author_id"
        case likeCount = "like_count"
        case commentCount = "comment_count"
        case createdAt = "created_at"
        case categoryId = "category_id"
        case forumCategories = "forum_categories"
    }

    init(
        id: Int,
        title: String,
        content: String? = nil,
        imageUrl: String? = nil,
        authorDisplayName: String? = nil,
        authorId: UUID? = nil,
        likeCount: Int? = nil,
        commentCount: Int? = nil,
        createdAt: Date? = nil,
        categoryId: Int? = nil,
        category: ForumCategory? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.imageUrl = imageUrl
        self.authorDisplayName = authorDisplayName
        self.authorId = authorId
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.createdAt = createdAt
        self.categoryId = categoryId
        self.forumCategories = category
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        authorDisplayName = try container.decodeIfPresent(String.self, forKey: .authorDisplayName)
        authorId = try container.decodeIfPresent(UUID.self, forKey: .authorId)
        likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount)
        commentCount = try container.decodeIfPresent(Int.self, forKey: .commentCount)
        createdAt = try container.decodeFilmilaTimestampIfPresent(forKey: .createdAt)
        categoryId = try container.decodeIfPresent(Int.self, forKey: .categoryId)
        forumCategories = try container.decodeIfPresent(ForumCategory.self, forKey: .forumCategories)
    }

    var displayAuthorName: String {
        let trimmed = authorDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? String(localized: "community_author_anonymous") : trimmed
    }

    var displayCategoryName: String {
        forumCategories?.name ?? String(localized: "community_category_general")
    }

    var displayLikeCount: Int { likeCount ?? 0 }
    var displayCommentCount: Int { commentCount ?? 0 }
}
