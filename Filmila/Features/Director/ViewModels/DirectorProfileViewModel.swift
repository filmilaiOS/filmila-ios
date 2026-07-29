import Foundation

@MainActor
final class DirectorProfileViewModel: ObservableObject {
    @Published private(set) var profile: FilmmakerProfile?
    @Published private(set) var films: [Film] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let directorId: UUID
    private let filmsRepo: FilmsRepositoryProtocol

    init(directorId: UUID, container: AppContainer) {
        self.directorId = directorId
        filmsRepo = container.filmsRepo
    }

    var averageRating: Double {
        let rated = films.compactMap(\.averageRating).filter { $0 > 0 }
        guard !rated.isEmpty else { return 0 }
        return rated.reduce(0, +) / Double(rated.count)
    }

    var totalViews: Int {
        films.reduce(0) { $0 + $1.viewCount }
    }

    var filmCount: Int {
        films.count
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            guard let loaded = try await filmsRepo.fetchFilmmakerProfile(directorId: directorId) else {
                profile = nil
                films = []
                errorMessage = String(localized: "director_profile_unavailable_body")
                return
            }
            profile = loaded
            if let email = loaded.email?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty {
                films = try await filmsRepo.fetchApprovedFilms(filmmakerEmail: email)
            } else {
                films = []
            }
        } catch {
            profile = nil
            films = []
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
