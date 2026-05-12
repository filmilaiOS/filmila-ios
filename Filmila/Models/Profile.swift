import Foundation

struct Profile: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let role: String
    let fullName: String?
    let avatarUrl: String?
    let apnsToken: String?

    enum CodingKeys: String, CodingKey {
        case id
        case role
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case apnsToken = "apns_token"
    }
}
