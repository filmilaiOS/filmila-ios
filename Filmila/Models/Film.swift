import Foundation

struct Film: Identifiable, Equatable, Sendable {
    let id: Int
    let title: String
    let synopsis: String?
    /// Whole currency units or minor units as defined by your backend; free when zero.
    let price: Int
}
