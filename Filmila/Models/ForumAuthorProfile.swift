import Foundation

struct ForumAuthorProfile: Codable, Equatable {
    let fullName: String?

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
    }
}
