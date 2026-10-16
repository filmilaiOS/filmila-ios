import Foundation
import Supabase

protocol ForumRepositoryProtocol: AnyObject {
    func fetchCategories() async throws -> [ForumCategory]
    func fetchPosts(categoryId: Int?) async throws -> [ForumPost]
    func fetchPost(id: Int) async throws -> ForumPost
    func fetchComments(postId: Int) async throws -> [ForumComment]
}

enum ForumRepositoryError: Error {
    case postNotFound
}

/// Read-only repository for community/forum content.
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
