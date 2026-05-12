import Foundation
import Supabase

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let jsonDecoder: JSONDecoder

    private init() {
        session = URLSession.shared
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let basic = ISO8601DateFormatter()
        basic.formatOptions = [.withInternetDateTime]
        decoder.dateDecodingStrategy = .custom { dec in
            let container = try dec.singleValueContainer()
            if let date = try? container.decode(Date.self) {
                return date
            }
            let string = try container.decode(String.self)
            if let date = fractional.date(from: string) ?? basic.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO8601 date: \(string)")
        }
        jsonDecoder = decoder
    }

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        var request = try endpoint.urlRequest()
        if let token = try? await SupabaseManager.shared.client.auth.session.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }

        switch http.statusCode {
        case 200 ..< 300:
            break
        case 401:
            throw NetworkError.unauthorized
        case 404:
            throw NetworkError.notFound
        case 500 ..< 600:
            let message = String(data: data, encoding: .utf8) ?? "Server error"
            throw NetworkError.serverError(message)
        default:
            throw NetworkError.httpError(http.statusCode)
        }

        do {
            return try jsonDecoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    /// Performs a request (e.g. POST) with the signed-in Supabase access token; does not decode a body.
    func performAuthorized(_ request: URLRequest) async throws {
        var request = request
        if let token = try? await SupabaseManager.shared.client.auth.session.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }

        switch http.statusCode {
        case 200 ..< 300:
            return
        case 401:
            throw NetworkError.unauthorized
        case 404:
            throw NetworkError.notFound
        case 500 ..< 600:
            let message = String(data: data, encoding: .utf8) ?? "Server error"
            throw NetworkError.serverError(message)
        default:
            throw NetworkError.httpError(http.statusCode)
        }
    }
}
