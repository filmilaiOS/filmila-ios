import Foundation

/// Reads public filmmaker profile fields via PostgREST with the anon key only.
/// Authenticated Supabase sessions can be blocked by RLS from reading other users' `profiles` rows;
/// anon policies typically allow public display fields (name, avatar, bio, location).
enum PublicFilmmakerProfileFetcher {
    private static let selectColumns = "id,display_name,avatar_url,bio,location,email"

    static func fetch(filmmakerEmail: String) async throws -> FilmmakerProfile? {
        let trimmed = filmmakerEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return try await fetchRows(queryItems: [
            URLQueryItem(name: "email", value: "eq.\(trimmed)"),
            URLQueryItem(name: "select", value: selectColumns),
            URLQueryItem(name: "limit", value: "1"),
        ]).first
    }

    static func fetch(directorId: UUID) async throws -> FilmmakerProfile? {
        return try await fetchRows(queryItems: [
            URLQueryItem(name: "id", value: "eq.\(directorId.uuidString.lowercased())"),
            URLQueryItem(name: "select", value: selectColumns),
            URLQueryItem(name: "limit", value: "1"),
        ]).first
    }

    private static func fetchRows(queryItems: [URLQueryItem]) async throws -> [FilmmakerProfile] {
        var components = URLComponents(
            url: Env.supabaseURL.appendingPathComponent("rest/v1/profiles"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = queryItems
        guard let url = components?.url else { return [] }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(Env.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(Env.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { return [] }
        guard (200 ..< 300).contains(http.statusCode) else { return [] }

        return try JSONDecoder().decode([FilmmakerProfile].self, from: data)
    }
}
