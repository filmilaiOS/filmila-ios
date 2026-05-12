import Foundation
import StoreKit

enum PaymentState: Equatable {
    case idle
    case loading
    case success
    case failed(String)
    case cancelled
}

@MainActor
final class PaymentViewModel: ObservableObject {
    @Published private(set) var state: PaymentState = .idle
    @Published private(set) var storeProduct: Product?

    private let filmId: Int
    private let iapService: IAPServiceProtocol

    init(filmId: Int, iapService: IAPServiceProtocol) {
        self.filmId = filmId
        self.iapService = iapService
    }

    func configure(initialStoreProduct: Any?) {
        if let product = initialStoreProduct as? Product {
            storeProduct = product
        }
    }

    func loadStoreProductIfNeeded() async {
        guard storeProduct == nil else { return }
        do {
            storeProduct = try await iapService.loadProduct(filmId: filmId) as? Product
        } catch {
            storeProduct = nil
        }
    }

    func purchase(filmId: Int) async {
        state = .loading
        do {
            let outcome = try await iapService.purchase(filmId: filmId)
            switch outcome {
            case .success:
                state = .success
            case .cancelled:
                state = .cancelled
            case .pending:
                state = .failed(String(localized: "iap_pending"))
            case let .failed(error):
                state = .failed((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
            }
        } catch {
            state = .failed((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
        }
    }

    func restore() async {
        state = .loading
        do {
            try await iapService.restorePurchases()
            state = .success
        } catch {
            state = .failed((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
        }
    }

    func resetToIdle() {
        state = .idle
    }
}
