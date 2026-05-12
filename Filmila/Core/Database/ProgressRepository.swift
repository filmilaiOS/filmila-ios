import Foundation
import Supabase

protocol ProgressRepositoryProtocol: AnyObject {
    func saveProgress(filmId: Int, seconds: Int) async throws
    func fetchProgress(filmId: Int) async throws -> FilmProgress?
    func fetchContinueWatching() async throws -> [FilmProgress]
}

final class LiveProgressRepository: ProgressRepositoryProtocol {
    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private var client: SupabaseClient { SupabaseManager.shared.client }

    private func currentUserId() async throws -> UUID {
        try await client.auth.session.user.id
    }

    func saveProgress(filmId: Int, seconds: Int) async throws {
        let userId = try await currentUserId()
        let existing = try await fetchProgress(filmId: filmId)
        let id = existing?.id ?? UUID()
        let row = FilmProgressUpsert(
            id: id.uuidString,
            userId: userId.uuidString,
            filmId: filmId,
            progressSeconds: seconds,
            completedAt: existing?.completedAt.map { Self.iso8601.string(from: $0) },
            updatedAt: Self.iso8601.string(from: Date())
        )
        try await client.from("film_progress")
            .upsert(row, onConflict: "user_id,film_id")
            .execute()
    }

    func fetchProgress(filmId: Int) async throws -> FilmProgress? {
        let userId = try await currentUserId()
        let rows: [FilmProgress] = try await client.from("film_progress")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("film_id", value: filmId)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    func fetchContinueWatching() async throws -> [FilmProgress] {
        let userId = try await currentUserId()
        return try await client.from("film_progress")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("updated_at", ascending: false)
            .limit(10)
            .execute()
            .value
    }

    private struct FilmProgressUpsert: Encodable {
        let id: String
        let userId: String
        let filmId: Int
        let progressSeconds: Int
        let completedAt: String?
        let updatedAt: String

        enum CodingKeys: String, CodingKey {
            case id
            case userId = "user_id"
            case filmId = "film_id"
            case progressSeconds = "progress_seconds"
            case completedAt = "completed_at"
            case updatedAt = "updated_at"
        }
    }
}
