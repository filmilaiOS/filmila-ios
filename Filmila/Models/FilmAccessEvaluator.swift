import Foundation

enum FilmAccessEvaluator: Sendable {
    static func isFree(price: Double) -> Bool {
        price == 0
    }

    static func canWatch(price: Double, hasCompletedPayment: Bool) -> Bool {
        isFree(price: price) || hasCompletedPayment
    }
}
