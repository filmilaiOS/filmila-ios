import Foundation

@MainActor
final class CommunityFeedViewModel: ObservableObject {
    @Published private(set) var categories: [ForumCategory] = []
    @Published private(set) var posts: [ForumPost] = []
    @Published var selectedCategoryId: Int?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let repo: ForumRepositoryProtocol

    init(container: AppContainer) {
        repo = container.forumRepo
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let categoriesTask = repo.fetchCategories()
            async let postsTask = repo.fetchPosts(categoryId: selectedCategoryId)
            categories = try await categoriesTask
            posts = try await postsTask
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            posts = []
        }
    }

    func selectCategory(_ categoryId: Int?) async {
        selectedCategoryId = categoryId
        await reloadPosts()
    }

    func reloadPosts() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            posts = try await repo.fetchPosts(categoryId: selectedCategoryId)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            posts = []
        }
    }
}
