import Foundation

struct CommentDisplay: Identifiable, Equatable, Sendable {
    let id: UUID
    let filmId: Int
    let userId: UUID
    let content: String
    let createdAt: Date
    let authorDisplayName: String?
}
