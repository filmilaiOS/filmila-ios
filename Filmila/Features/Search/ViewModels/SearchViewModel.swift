import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var results: [Film] = []
    @Published var selectedGenre: String?
    @Published private(set) var isLoading = false

    private let filmsRepo: FilmsRepositoryProtocol
    private var debounceTask: Task<Void, Never>?

    init(container: AppContainer) {
        filmsRepo = container.filmsRepo
    }

    /// Call when `query` or `selectedGenre` changes. Debounces 300ms and cancels any in-flight debounce/search.
    func onSearchControlsChanged() {
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(nanoseconds: 300_000_000)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            await self.executeSearch()
        }
    }

    private func executeSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            results = []
            isLoading = false
            return
        }

        isLoading = true
        defer { isLoading = false }

        let genre = selectedGenre
        do {
            results = try await filmsRepo.searchFilms(query: trimmed, genre: genre)
        } catch {
            results = []
        }
    }

    func cancelPendingSearch() {
        debounceTask?.cancel()
        debounceTask = nil
    }
}
