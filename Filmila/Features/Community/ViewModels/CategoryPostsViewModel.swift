import Foundation

@MainActor
final class CategoryPostsViewModel: ObservableObject {
    let category: ForumCategory

    @Published private(set) var posts: [ForumPost] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let repo: ForumRepositoryProtocol

    init(category: ForumCategory, container: AppContainer) {
        self.category = category
        repo = container.forumRepo
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            posts = try await repo.fetchPosts(categoryId: category.id)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            posts = []
        }
    }
}
