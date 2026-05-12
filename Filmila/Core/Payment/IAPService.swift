import Foundation
import StoreKit

enum PurchaseOutcome {
    case success
    case cancelled
    case pending
    case failed(any Error)
}

protocol IAPServiceProtocol: AnyObject {
    /// Returns a StoreKit `Product` when available in App Store Connect for this film id.
    func loadProduct(filmId: Int) async throws -> Any?
    func purchase(filmId: Int) async throws -> PurchaseOutcome
    func restorePurchases() async throws
    func hasPurchased(filmId: Int) async -> Bool
}

enum IAPServiceError: LocalizedError {
    case productUnavailable
    case purchaseFailed(String)
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .productUnavailable:
            return String(localized: "iap_product_unavailable")
        case let .purchaseFailed(message):
            return message
        case .notSignedIn:
            return String(localized: "iap_not_signed_in")
        }
    }
}

final class IAPService: IAPServiceProtocol {
    private func productIdentifier(for filmId: Int) -> String {
        "com.filmila.film.\(filmId)"
    }

    func loadProduct(filmId: Int) async throws -> Any? {
        let id = productIdentifier(for: filmId)
        let products = try await Product.products(for: [id])
        return products.first
    }

    func purchase(filmId: Int) async throws -> PurchaseOutcome {
        guard let resolved = try await loadProduct(filmId: filmId) as? Product else {
            throw IAPServiceError.productUnavailable
        }

        let result = try await resolved.purchase()
        switch result {
        case let .success(verification):
            let transaction: Transaction
            do {
                transaction = try checkVerified(verification)
            } catch {
                return .failed(error)
            }
            await transaction.finish()
            do {
                try await notifyServer(transaction: transaction, filmId: filmId)
            } catch {
                return .failed(error)
            }
            return .success
        case .userCancelled:
            return .cancelled
        case .pending:
            return .pending
        @unknown default:
            return .failed(IAPServiceError.purchaseFailed(String(localized: "iap_unknown")))
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
    }

    func hasPurchased(filmId: Int) async -> Bool {
        let pid = productIdentifier(for: filmId)
        for await entitlement in Transaction.currentEntitlements {
            guard case let .verified(transaction) = entitlement else { continue }
            if transaction.productID == pid {
                return true
            }
        }
        return false
    }

    private func checkVerified(_ result: VerificationResult<Transaction>) throws -> Transaction {
        switch result {
        case let .unverified(_, error):
            throw error
        case let .verified(safe):
            return safe
        }
    }

    private func notifyServer(transaction: Transaction, filmId: Int) async throws {
        let userId = try await currentUserUUIDString()
        let request = try Endpoint.recordIAPPurchase(
            filmId: filmId,
            transactionId: String(transaction.id),
            userId: userId
        ).urlRequest()
        try await APIClient.shared.performAuthorized(request)
    }

    private func currentUserUUIDString() async throws -> String {
        guard let session = try? await SupabaseManager.shared.client.auth.session else {
            throw IAPServiceError.notSignedIn
        }
        return session.user.id.uuidString
    }
}
