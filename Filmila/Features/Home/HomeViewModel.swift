import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    enum Phase: Equatable {
        case idle
        case loading
        case content([Film])
        case empty
        case failed(String)
    }

    @Published private(set) var phase: Phase = .idle

    private let filmCatalog: FilmCatalogServing

    init(filmCatalog: FilmCatalogServing) {
        self.filmCatalog = filmCatalog
    }

    func load() async {
        phase = .loading
        do {
            let items = try await filmCatalog.films()
            if items.isEmpty {
                phase = .empty
            } else {
                phase = .content(items)
            }
        } catch FilmCatalogError.supabaseNotConfigured {
            phase = .failed(String(localized: "config_error"))
        } catch {
            phase = .failed(String(localized: "home_error"))
        }
    }
}
