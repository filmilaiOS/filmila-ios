import Foundation
import Supabase

private struct FilmRow: Decodable {
    let id: Int
    let title: String
    let synopsis: String?
    let price: FlexibleInt

    struct FlexibleInt: Decodable {
        let value: Int

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let intVal = try? container.decode(Int.self) {
                value = intVal
                return
            }
            if let doubleVal = try? container.decode(Double.self) {
                value = Int(doubleVal.rounded())
                return
            }
            if let stringVal = try? container.decode(String.self), let parsed = Int(stringVal) {
                value = parsed
                return
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected numeric price")
        }
    }

    func toDomain() -> Film {
        Film(id: id, title: title, synopsis: synopsis, price: price.value)
    }
}

private struct FilmPaymentRow: Decodable {
    let id: String?
}

actor LiveFilmCatalogService: FilmCatalogServing {
    private let client: SupabaseClient
    private let configuration: AppConfiguration

    init(configuration: AppConfiguration, client: SupabaseClient) {
        self.configuration = configuration
        self.client = client
    }

    init?(configuration: AppConfiguration) {
        guard configuration.isSupabaseConfigured,
              let url = configuration.supabaseURL else {
            return nil
        }
        self.configuration = configuration
        self.client = SupabaseClient(supabaseURL: url, supabaseKey: configuration.supabaseAnonKey)
    }

    func films() async throws -> [Film] {
        guard configuration.isSupabaseConfigured else {
            throw FilmCatalogError.supabaseNotConfigured
        }
        let rows: [FilmRow] = try await client
            .from("films")
            .select("id,title,synopsis,price")
            .order("id", ascending: true)
            .execute()
            .value
        return rows.map { $0.toDomain() }
    }

    func canViewerWatch(filmId: Int) async throws -> Bool {
        guard configuration.isSupabaseConfigured else {
            throw FilmCatalogError.supabaseNotConfigured
        }
        let filmRows: [FilmRow] = try await client
            .from("films")
            .select("id,title,synopsis,price")
            .eq("id", value: filmId)
            .limit(1)
            .execute()
            .value
        guard let film = filmRows.first?.toDomain() else {
            return false
        }
        if FilmAccessEvaluator.isFree(price: film.price) {
            return true
        }
        let session: Session
        do {
            session = try await client.auth.session
        } catch {
            throw FilmCatalogError.notSignedIn
        }
        let viewerId = session.user.id.uuidString
        let payments: [FilmPaymentRow] = try await client
            .from("film_payments")
            .select("id")
            .eq("film_id", value: filmId)
            .eq("viewer_id", value: viewerId)
            .eq("status", value: "completed")
            .limit(1)
            .execute()
            .value
        return FilmAccessEvaluator.canWatch(price: film.price, hasCompletedPayment: !payments.isEmpty)
    }
}
