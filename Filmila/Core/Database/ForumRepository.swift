import Foundation
import Supabase

protocol ForumRepositoryProtocol: AnyObject {
    func fetchCategories() async throws -> [ForumCategory]
    func fetchPosts(categoryId: Int?) async throws -> [ForumPost]
    func fetchPost(id: Int) async throws -> ForumPost
    func fetchComments(postId: Int) async throws -> [ForumComment]
    func createComment(postId: Int, content: String) async throws
}

enum ForumRepositoryError: Error {
    case postNotFound
}

/// Community repository for reading posts and submitting comments.
final class LiveForumRepository: ForumRepositoryProtocol {
    private var client: SupabaseClient { SupabaseManager.shared.client }

    func fetchCategories() async throws -> [ForumCategory] {
        try await client
            .from("forum_categories")
            .select("id,name,description,color,created_at")
            .order("name", ascending: true)
            .execute()
            .value
    }

    func fetchPosts(categoryId: Int?) async throws -> [ForumPost] {
        var q = client
            .from("forum_posts")
            .select(
                "id,title,content,author_id,author_display_name,image_url,created_at,category_id,forum_categories(id,name)"
            )

        if let categoryId {
            q = q.eq("category_id", value: categoryId)
        }

        let posts: [ForumPost] = try await q.order("created_at", ascending: false).execute().value
        let blocked = (try? await ForumSafetyService.shared.blockedIds()) ?? []
        return posts.filter { $0.authorId.map { !blocked.contains($0) } ?? true }
    }

    func fetchPost(id: Int) async throws -> ForumPost {
        let rows: [ForumPost] = try await client
            .from("forum_posts")
            .select(
                "id,title,content,author_id,author_display_name,image_url,created_at,category_id,forum_categories(id,name)"
            )
            .eq("id", value: id)
            .limit(1)
            .execute()
            .value

        guard let post = rows.first else {
            throw ForumRepositoryError.postNotFound
        }
        let blocked = (try? await ForumSafetyService.shared.blockedIds()) ?? []
        guard post.authorId.map({ !blocked.contains($0) }) ?? true else { throw ForumRepositoryError.postNotFound }
        return post
    }

    func createComment(postId: Int, content: String) async throws {
        let session = try await client.auth.session
        let userId = session.user.id
        let cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanContent.isEmpty else { throw ForumCommentSubmissionError.empty }
        guard cleanContent.count <= 2000 else { throw ForumCommentSubmissionError.tooLong }

        struct AuthorProfile: Decodable {
            let role: String?
            let display_name: String?
        }
        let profile: AuthorProfile = try await client.from("profiles")
            .select("role,display_name")
            .eq("id", value: userId.uuidString)
            .single()
            .execute().value
        let role = (profile.role ?? "").uppercased()
        guard role == "VIEWER" || role == "FILMMAKER" else {
            throw ForumCommentSubmissionError.notAllowed
        }

        struct NewComment: Encodable {
            let post_id: Int
            let content: String
            let author_id: UUID
            let author_role: String
            let author_display_name: String
        }
        let fallback = session.user.email?.split(separator: "@").first.map(String.init) ?? "Filmila user"
        let payload = NewComment(
            post_id: postId,
            content: cleanContent,
            author_id: userId,
            author_role: role,
            author_display_name: profile.display_name ?? fallback
        )
        try await client.from("forum_comments").insert(payload).execute()
    }

    func fetchComments(postId: Int) async throws -> [ForumComment] {
        let comments: [ForumComment] = try await client
            .from("forum_comments")
            .select("id,post_id,content,author_id,author_display_name,created_at")
            .eq("post_id", value: postId)
            .order("created_at", ascending: true)
            .execute()
            .value
        let blocked = (try? await ForumSafetyService.shared.blockedIds()) ?? []
        return comments.filter { $0.authorId.map { !blocked.contains($0) } ?? true }
    }
}

enum ForumCommentSubmissionError: LocalizedError {
    case empty, tooLong, notAllowed

    var errorDescription: String? {
        switch self {
        case .empty: return String(localized: "community_comment_empty_error")
        case .tooLong: return String(localized: "community_comment_length_error")
        case .notAllowed: return String(localized: "community_comment_not_allowed")
        }
    }
}
