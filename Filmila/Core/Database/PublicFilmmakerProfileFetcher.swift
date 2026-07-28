import Foundation

/// Reads public filmmaker profile fields via PostgREST with the anon key only.
/// Authenticated Supabase sessions can be blocked by RLS from reading other users' `profiles` rows;
/// anon policies typically allow public display fields (name, avatar).
enum PublicFilmmakerProfileFetcher {
    private struct Row: Decodable {
        let id: UUID
        let displayName: String?
        let avatarUrl: String?

        enum CodingKeys: String, CodingKey {
            case id
            case displayName = "display_name"
            case avatarUrl = "avatar_url"
        }
    }

    static func fetch(filmmakerEmail: String) async throws -> FilmmakerProfile? {
        let trimmed = filmmakerEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        var components = URLComponents(
            url: Env.supabaseURL.appendingPathComponent("rest/v1/profiles"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "email", value: "eq.\(trimmed)"),
            URLQueryItem(name: "select", value: "id,display_name,avatar_url"),
            URLQueryItem(name: "limit", value: "1"),
        ]
        guard let url = components?.url else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(Env.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(Env.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { return nil }
        guard (200 ..< 300).contains(http.statusCode) else { return nil }

        let rows = try JSONDecoder().decode([Row].self, from: data)
        guard let row = rows.first else { return nil }
        return FilmmakerProfile(
            id: row.id,
            displayName: row.displayName,
            avatarUrl: row.avatarUrl
        )
    }
}
