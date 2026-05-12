import Combine
import Foundation

@MainActor
final class PlayerViewModel: ObservableObject {
    let playerService: HLSPlayerService

    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var showRetry = false

    private let film: Film
    private let progressRepo: ProgressRepositoryProtocol
    private let networkMonitor: NetworkMonitor
    private var cancellables = Set<AnyCancellable>()

    init(film: Film, container: AppContainer, networkMonitor: NetworkMonitor) {
        self.film = film
        self.progressRepo = container.progressRepo
        self.networkMonitor = networkMonitor
        playerService = HLSPlayerService(
            s3Service: container.s3Service,
            progressRepo: container.progressRepo,
            networkMonitor: networkMonitor
        )

        networkMonitor.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.playerService.handleNetworkChange(isConnected: self.networkMonitor.isConnected)
            }
            .store(in: &cancellables)

        playerService.$playbackState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case let .failed(message):
                    self.errorMessage = message
                    self.showRetry = true
                case .playing:
                    self.showRetry = false
                    self.errorMessage = nil
                default:
                    break
                }
            }
            .store(in: &cancellables)

        playerService.handleNetworkChange(isConnected: networkMonitor.isConnected)
    }

    func startPlayback() async throws {
        isLoading = true
        errorMessage = nil
        showRetry = false
        defer { isLoading = false }
        do {
            let progress = try? await progressRepo.fetchProgress(filmId: film.id)
            try await playerService.preparePlayback(film: film, resumeFrom: progress)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            errorMessage = message
            showRetry = true
            throw error
        }
    }

    func retryPlayback() async throws {
        try await startPlayback()
    }

    func cleanup() {
        cancellables.removeAll()
        playerService.cleanup()
    }
}
