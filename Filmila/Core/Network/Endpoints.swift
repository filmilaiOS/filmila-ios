import Foundation

enum EndpointError: Error {
    case invalidURL
}

enum KeychainKeys {
    /// Optional Bearer for Vercel `/api/*` on `Endpoint.urlRequest()` (Supabase session overrides in `APIClient`).
    static let apiAuthorizationBearer = "filmila.api.authorization_bearer"
}

enum Endpoint {
    // presigned-playback removed — not deployed on production; presign-upload handles playback signing.
    case presignUpload(filmId: Int)
    case recordIAPPurchase(filmId: Int, transactionId: String, userId: String)
    case sendTicketEmail(filmId: Int, userId: String)

    func urlRequest() throws -> URLRequest {
        switch self {
        case let .presignUpload(filmId):
            guard var components = URLComponents(
                url: Env.apiBaseURL.appendingPathComponent("api/presign-upload", isDirectory: false),
                resolvingAgainstBaseURL: false
            ) else {
                throw EndpointError.invalidURL
            }
            components.queryItems = [URLQueryItem(name: "filmId", value: String(filmId))]
            guard let url = components.url else {
                throw EndpointError.invalidURL
            }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            return Self.applyBearer(to: request)

        case let .recordIAPPurchase(filmId, transactionId, userId):
            let url = Env.apiBaseURL.appendingPathComponent("api/record-iap-purchase", isDirectory: false)
            let body = RecordIAPBody(filmId: filmId, transactionId: transactionId, userId: userId)
            return try Self.postJSON(url: url, body: body)

        case let .sendTicketEmail(filmId, userId):
            let url = Env.apiBaseURL.appendingPathComponent("api/send-ticket-email", isDirectory: false)
            let body = SendTicketEmailBody(filmId: filmId, userId: userId)
            return try Self.postJSON(url: url, body: body)
        }
    }

    private static func applyBearer(to request: URLRequest) -> URLRequest {
        var request = request
        if let token = KeychainManager.load(key: KeychainKeys.apiAuthorizationBearer) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private static func postJSON<T: Encodable>(url: URL, body: T) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return applyBearer(to: request)
    }

    private struct RecordIAPBody: Encodable {
        let filmId: Int
        let transactionId: String
        let userId: String
    }

    private struct SendTicketEmailBody: Encodable {
        let filmId: Int
        let userId: String

        enum CodingKeys: String, CodingKey {
            case filmId = "film_id"
            case userId = "user_id"
        }
    }
}
