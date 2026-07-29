import Foundation

struct FilmmakerProfile: Identifiable, Decodable, Equatable, Sendable {
    let id: UUID
    let displayName: String?
    let avatarUrl: String?
    let bio: String?
    let location: String?
    let email: String?

    init(
        id: UUID,
        displayName: String? = nil,
        avatarUrl: String? = nil,
        bio: String? = nil,
        location: String? = nil,
        email: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.bio = bio
        self.location = location
        self.email = email
    }

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case bio
        case location
        case email
    }

    /// Non-empty `avatar_url` from the filmmaker's profile row.
    var resolvedAvatarURL: String? {
        guard let raw = avatarUrl?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        return raw
    }

    var resolvedDisplayName: String {
        let trimmed = displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmed.isEmpty { return trimmed }
        return String(localized: "detail_director_fallback")
    }

    var resolvedBio: String? {
        let trimmed = bio?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    var resolvedLocation: String? {
        let trimmed = location?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}
