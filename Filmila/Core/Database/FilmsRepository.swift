import Foundation
import Supabase

enum FilmsRepositoryError: Error {
    case filmNotFound
}

protocol FilmsRepositoryProtocol: AnyObject {
    func fetchApprovedFilms() async throws -> [Film]
    func fetchFilm(id: Int) async throws -> Film
    func searchFilms(query: String, genre: String?) async throws -> [Film]
    func fetchFeatured() async throws -> [Film]
    func fetchTrending() async throws -> [Film]
    func toggleWatchlist(filmId: Int, add: Bool) async throws
    func toggleFavorite(filmId: Int, add: Bool) async throws
    func fetchWatchlist() async throws -> [Film]
    func fetchFavorites() async throws -> [Film]
    /// Completed (and other) payment rows for the signed-in viewer, newest first.
    func fetchPurchaseHistory() async throws -> [FilmPayment]
    /// Approved films matching the given ids (order is not guaranteed).
    func fetchFilms(byIds ids: [Int]) async throws -> [Film]
    func fetchCommentsWithAuthors(filmId: Int) async throws -> [CommentDisplay]
    func fetchFilmRatingsAggregate(filmId: Int) async throws -> (average: Double, count: Int)
    func fetchUserFilmRating(filmId: Int) async throws -> Int?
    func upsertUserFilmRating(filmId: Int, rating: Int) async throws
    func insertComment(filmId: Int, text: String) async throws
    func isFilmInWatchlist(filmId: Int) async throws -> Bool
    func isFilmInFavorites(filmId: Int) async throws -> Bool
}

/// Supabase tables assumed: `films`, `film_watchlist` (`user_id`, `film_id`), `film_favorites` (`user_id`, `film_id`),
/// `comments`, `film_ratings`, `profiles`.
final class LiveFilmsRepository: FilmsRepositoryProtocol {
    private let filmSelectColumns =
        "id,title,title_ar,description,description_ar,thumbnail_url,hls_url,video_url,price,status,genre,duration,view_count,created_at"

    private var client: SupabaseClient { SupabaseManager.shared.client }

    private func currentUserId() async throws -> UUID {
        try await client.auth.session.user.id
    }

    func fetchApprovedFilms() async throws -> [Film] {
        let rows: [Film] = try await client.from("films")
            .select(filmSelectColumns)
            .eq("status", value: "approved")
            .order("id", ascending: true)
            .execute()
            .value
        return FilmsApprovedCatalogPolicy.filterApprovedOnly(rows)
    }

    func fetchFilm(id: Int) async throws -> Film {
        let rows: [Film] = try await client.from("films")
            .select(filmSelectColumns)
            .eq("status", value: "approved")
            .eq("id", value: id)
            .limit(1)
            .execute()
            .value
        guard let film = rows.first else {
            throw FilmsRepositoryError.filmNotFound
        }
        return film
    }

    func searchFilms(query: String, genre: String?) async throws -> [Film] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        var q = client.from("films").select(filmSelectColumns).eq("status", value: "approved")
        if !trimmed.isEmpty {
            let pattern = Self.ilikePattern(trimmed)
            q = q.or("title.ilike.\(pattern),description.ilike.\(pattern)")
        }
        if let genre, !genre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            q = q.eq("genre", value: genre.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return try await q.order("view_count", ascending: false).execute().value
    }

    func fetchFeatured() async throws -> [Film] {
        try await client.from("films")
            .select(filmSelectColumns)
            .eq("status", value: "approved")
            .order("view_count", ascending: false)
            .limit(5)
            .execute()
            .value
    }

    func fetchTrending() async throws -> [Film] {
        try await client.from("films")
            .select(filmSelectColumns)
            .eq("status", value: "approved")
            .order("view_count", ascending: false)
            .limit(20)
            .execute()
            .value
    }

    func toggleWatchlist(filmId: Int, add: Bool) async throws {
        let userId = try await currentUserId()
        if add {
            let row = UserFilmRow(userId: userId, filmId: filmId)
            try await client.from("film_watchlist").insert(row).execute()
        } else {
            try await client.from("film_watchlist")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .eq("film_id", value: filmId)
                .execute()
        }
    }

    func toggleFavorite(filmId: Int, add: Bool) async throws {
        let userId = try await currentUserId()
        if add {
            let row = UserFilmRow(userId: userId, filmId: filmId)
            try await client.from("film_favorites").insert(row).execute()
        } else {
            try await client.from("film_favorites")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .eq("film_id", value: filmId)
                .execute()
        }
    }

    func fetchWatchlist() async throws -> [Film] {
        let userId = try await currentUserId()
        let rows: [FilmIdOnlyRow] = try await client
            .from("film_watchlist")
            .select("film_id")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        return try await fetchFilmsByIds(rows.map(\.filmId))
    }

    func fetchFavorites() async throws -> [Film] {
        let userId = try await currentUserId()
        let rows: [FilmIdOnlyRow] = try await client
            .from("film_favorites")
            .select("film_id")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        return try await fetchFilmsByIds(rows.map(\.filmId))
    }

    func fetchPurchaseHistory() async throws -> [FilmPayment] {
        let userId = try await currentUserId()
        return try await client.from("film_payments")
            .select()
            .eq("viewer_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func fetchFilms(byIds ids: [Int]) async throws -> [Film] {
        try await fetchFilmsByIds(ids)
    }

    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    func fetchCommentsWithAuthors(filmId: Int) async throws -> [CommentDisplay] {
        do {
            let rows: [CommentWithProfileRow] = try await client.from("comments")
                .select("id,film_id,user_id,content,created_at,profiles(full_name)")
                .eq("film_id", value: filmId)
                .order("created_at", ascending: false)
                .execute()
                .value
            return rows.map { $0.display }
        } catch {
            let rows: [Comment] = try await client.from("comments")
                .select()
                .eq("film_id", value: filmId)
                .order("created_at", ascending: false)
                .execute()
                .value
            return rows.map {
                CommentDisplay(
                    id: $0.id,
                    filmId: $0.filmId,
                    userId: $0.userId,
                    content: $0.content,
                    createdAt: $0.createdAt,
                    authorDisplayName: nil
                )
            }
        }
    }

    func fetchFilmRatingsAggregate(filmId: Int) async throws -> (average: Double, count: Int) {
        struct Row: Decodable {
            let rating: Int
        }
        let rows: [Row] = try await client.from("film_ratings")
            .select("rating")
            .eq("film_id", value: filmId)
            .execute()
            .value
        guard !rows.isEmpty else { return (0, 0) }
        let sum = rows.reduce(0) { $0 + $1.rating }
        return (Double(sum) / Double(rows.count), rows.count)
    }

    func fetchUserFilmRating(filmId: Int) async throws -> Int? {
        struct Row: Decodable {
            let rating: Int
        }
        let userId = try await currentUserId()
        let rows: [Row] = try await client.from("film_ratings")
            .select("rating")
            .eq("film_id", value: filmId)
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first?.rating
    }

    func upsertUserFilmRating(filmId: Int, rating: Int) async throws {
        let userId = try await currentUserId()
        let existingId: String? = try await {
            struct IdRow: Decodable {
                let id: UUID
            }
            let rows: [IdRow] = try await client.from("film_ratings")
                .select("id")
                .eq("film_id", value: filmId)
                .eq("user_id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value
            return rows.first?.id.uuidString
        }()
        let row = FilmRatingUpsert(
            id: existingId ?? UUID().uuidString,
            filmId: filmId,
            userId: userId.uuidString,
            rating: rating,
            createdAt: Self.iso8601.string(from: Date())
        )
        try await client.from("film_ratings")
            .upsert(row, onConflict: "user_id,film_id")
            .execute()
    }

    func insertComment(filmId: Int, text: String) async throws {
        let userId = try await currentUserId()
        let row = CommentInsert(
            id: UUID().uuidString,
            filmId: filmId,
            userId: userId.uuidString,
            content: text
        )
        try await client.from("comments").insert(row).execute()
    }

    func isFilmInWatchlist(filmId: Int) async throws -> Bool {
        let userId = try await currentUserId()
        let rows: [FilmIdOnlyRow] = try await client.from("film_watchlist")
            .select("film_id")
            .eq("user_id", value: userId.uuidString)
            .eq("film_id", value: filmId)
            .limit(1)
            .execute()
            .value
        return !rows.isEmpty
    }

    func isFilmInFavorites(filmId: Int) async throws -> Bool {
        let userId = try await currentUserId()
        let rows: [FilmIdOnlyRow] = try await client.from("film_favorites")
            .select("film_id")
            .eq("user_id", value: userId.uuidString)
            .eq("film_id", value: filmId)
            .limit(1)
            .execute()
            .value
        return !rows.isEmpty
    }

    private func fetchFilmsByIds(_ ids: [Int]) async throws -> [Film] {
        let unique = Array(Set(ids)).sorted()
        guard !unique.isEmpty else { return [] }
        return try await client.from("films")
            .select(filmSelectColumns)
            .eq("status", value: "approved")
            .in("id", values: unique)
            .order("view_count", ascending: false)
            .execute()
            .value
    }

    private static func ilikePattern(_ raw: String) -> String {
        let escaped = raw
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "%", with: "\\%")
            .replacingOccurrences(of: "_", with: "\\_")
        return "%\(escaped)%"
    }

    private struct UserFilmRow: Encodable {
        let userId: UUID
        let filmId: Int
        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case filmId = "film_id"
        }
    }

    private struct FilmIdOnlyRow: Decodable {
        let filmId: Int
        enum CodingKeys: String, CodingKey {
            case filmId = "film_id"
        }
    }

    private struct CommentWithProfileRow: Decodable {
        let id: UUID
        let filmId: Int
        let userId: UUID
        let content: String
        let createdAt: Date
        let profiles: ProfileSnippet?

        enum CodingKeys: String, CodingKey {
            case id
            case filmId = "film_id"
            case userId = "user_id"
            case content
            case createdAt = "created_at"
            case profiles
        }

        struct ProfileSnippet: Decodable {
            let fullName: String?
            enum CodingKeys: String, CodingKey {
                case fullName = "full_name"
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(UUID.self, forKey: .id)
            filmId = try container.decode(Int.self, forKey: .filmId)
            userId = try container.decode(UUID.self, forKey: .userId)
            content = try container.decode(String.self, forKey: .content)
            createdAt = try container.decodeFilmilaTimestamp(forKey: .createdAt)
            profiles = try container.decodeIfPresent(ProfileSnippet.self, forKey: .profiles)
        }

        var display: CommentDisplay {
            CommentDisplay(
                id: id,
                filmId: filmId,
                userId: userId,
                content: content,
                createdAt: createdAt,
                authorDisplayName: profiles?.fullName
            )
        }
    }

    private struct FilmRatingUpsert: Encodable {
        let id: String
        let filmId: Int
        let userId: String
        let rating: Int
        let createdAt: String

        enum CodingKeys: String, CodingKey {
            case id
            case filmId = "film_id"
            case userId = "user_id"
            case rating
            case createdAt = "created_at"
        }
    }

    private struct CommentInsert: Encodable {
        let id: String
        let filmId: Int
        let userId: String
        let content: String

        enum CodingKeys: String, CodingKey {
            case id
            case filmId = "film_id"
            case userId = "user_id"
            case content
        }
    }
}

/// Client-side guard matching the server contract for `fetchApprovedFilms` (unit-tested).
enum FilmsApprovedCatalogPolicy: Sendable {
    static func filterApprovedOnly(_ films: [Film]) -> [Film] {
        films.filter { $0.status == .approved }
    }
}
