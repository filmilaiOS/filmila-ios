import Foundation

struct FilmmakerProfile: Identifiable, Decodable {
    let id: UUID
    let displayName: String?
    let avatarUrl: String?

    /// Non-empty `avatar_url` from the filmmaker's profile row.
    var resolvedAvatarURL: String? {
        guard let raw = avatarUrl?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        return raw
    }
}
