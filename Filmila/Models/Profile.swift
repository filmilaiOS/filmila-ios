import Foundation

struct Profile: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let role: String
    let fullName: String?
    let displayName: String?
    let email: String?
    let avatarUrl: String?
    let apnsToken: String?

    enum CodingKeys: String, CodingKey {
        case id
        case role
        case fullName = "full_name"
        case displayName = "display_name"
        case email
        case avatarUrl = "avatar_url"
        case apnsToken = "apns_token"
    }

    /// Preferred display name from Supabase `profiles` (supports both column names).
    var resolvedDisplayName: String? {
        for candidate in [fullName, displayName] {
            let trimmed = candidate?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        return nil
    }

    var normalizedRole: String {
        role.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
}
