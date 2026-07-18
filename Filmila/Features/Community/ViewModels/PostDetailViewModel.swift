import Foundation

@MainActor
final class PostDetailViewModel: ObservableObject {
    @Published private(set) var post: ForumPost?
    @Published private(set) var comments: [ForumComment] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let postId: Int
    private let repo: ForumRepositoryProtocol

    init(postId: Int, container: AppContainer) {
        self.postId = postId
        repo = container.forumRepo
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
