import Foundation

@MainActor
final class PostDetailViewModel: ObservableObject {
    @Published private(set) var post: ForumPost?
    @Published private(set) var comments: [ForumComment] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var isSubmittingComment = false
    @Published private(set) var commentError: String?

    private let postId: Int
    private let repo: ForumRepositoryProtocol

    init(postId: Int, container: AppContainer) {
        self.postId = postId
        repo = container.forumRepo
    }

    func submitComment(_ content: String) async -> Bool {
        guard !isSubmittingComment else { return false }
        isSubmittingComment = true
        commentError = nil
        defer { isSubmittingComment = false }
        do {
            try await repo.createComment(postId: postId, content: content)
            comments = try await repo.fetchComments(postId: postId)
            return true
        } catch {
            commentError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let postTask = repo.fetchPost(id: postId)
            async let commentsTask = repo.fetchComments(postId: postId)
            post = try await postTask
            comments = try await commentsTask
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            post = nil
            comments = []
        }
    }
}
