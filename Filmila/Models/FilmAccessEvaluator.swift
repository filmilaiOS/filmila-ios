import Foundation

enum FilmAccessEvaluator: Sendable {
    /// Viewer may watch when the film is free or a completed payment exists (checked separately).
    static func isFree(price: Int) -> Bool {
        price == 0
    }

    static func canWatch(price: Int, hasCompletedPayment: Bool) -> Bool {
        isFree(price: price) || hasCompletedPayment
    }
}
