import Foundation
import Supabase

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let jsonDecoder: JSONDecoder
    private static var timedSessions: [TimeInterval: URLSession] = [:]
    private static let timedSessionsLock = NSLock()

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

    /// - Parameters:
    ///   - timeout: When set, caps the entire request (auth + network + decode) and configures URLSession timeouts.
    ///   - diagnosticsTag: When set, emits `[FilmilaPlayback]` logs around auth and `URLSession.data`.
    func request<T: Decodable>(
        _ endpoint: Endpoint,
        timeout: TimeInterval? = nil,
        diagnosticsTag: String? = nil
    ) async throws -> T {
        if let timeout {
            return try await withThrowingTaskGroup(of: T.self) { group in
                group.addTask {
                    try await self.performRequest(endpoint, timeout: timeout, diagnosticsTag: diagnosticsTag)
                }
                group.addTask {
                    try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                    throw NetworkError.timeout
                }
                guard let result = try await group.next() else {
                    throw NetworkError.timeout
                }
                group.cancelAll()
                return result
            }
        }
        return try await performRequest(endpoint, timeout: nil, diagnosticsTag: diagnosticsTag)
    }

    private func performRequest<T: Decodable>(
        _ endpoint: Endpoint,
        timeout: TimeInterval?,
        diagnosticsTag: String?,
        isRetryAfter401: Bool = false
    ) async throws -> T {
        var request = try endpoint.urlRequest()
        let requestURL = request.url?.absoluteString ?? "?"

        let keychainAuthBefore = request.value(forHTTPHeaderField: "Authorization")

        if let diagnosticsTag {
            PlaybackLogger.log(
                "\(diagnosticsTag) auth attach START url=\(requestURL) keychainAuthBefore=\(AuthTokenDiagnostics.describeAuthorizationHeader(keychainAuthBefore))",
                filmId: nil
            )
        }

        let supabaseSession: Session
        do {
            supabaseSession = try await resolveSupabaseSession(forceRefresh: isRetryAfter401, diagnosticsTag: diagnosticsTag)
        } catch {
            if let diagnosticsTag {
                PlaybackLogger.logError("\(diagnosticsTag) Supabase session resolve FAILED", error: error, filmId: nil)
            }
            if keychainAuthBefore == nil {
                if let diagnosticsTag {
                    PlaybackLogger.log("\(diagnosticsTag) WARNING no auth token available for this request", filmId: nil)
                }
            }
            throw error
        }

        request.setValue("Bearer \(supabaseSession.accessToken)", forHTTPHeaderField: "Authorization")

        if let diagnosticsTag {
            PlaybackLogger.log(
                "\(diagnosticsTag) Authorization header SENT: \(AuthTokenDiagnostics.describeAuthorizationHeader(request.value(forHTTPHeaderField: "Authorization")))",
                filmId: nil
            )
            PlaybackLogger.log("\(diagnosticsTag) URLSession.data START method=\(request.httpMethod ?? "GET") url=\(requestURL)", filmId: nil)
        }

        let activeSession = timeout.map { Self.timedSession(requestTimeout: $0) } ?? session
        let networkStarted = Date()

        let data: Data
        let http: HTTPURLResponse
        do {
            let response: URLResponse
            (data, response) = try await activeSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                if let diagnosticsTag {
                    PlaybackLogger.log("\(diagnosticsTag) URLSession.data DONE non-HTTP response", filmId: nil)
                }
                throw NetworkError.unknown
            }
            http = httpResponse
        } catch let urlError as URLError where urlError.code == .timedOut {
            if let diagnosticsTag {
                PlaybackLogger.logError(
                    "\(diagnosticsTag) URLSession.data TIMED OUT after \(String(format: "%.2f", Date().timeIntervalSince(networkStarted)))s",
                    error: urlError,
                    filmId: nil
                )
            }
            throw NetworkError.timeout
        } catch {
            if let diagnosticsTag {
                PlaybackLogger.logError(
                    "\(diagnosticsTag) URLSession.data FAILED after \(String(format: "%.2f", Date().timeIntervalSince(networkStarted)))s",
                    error: error,
                    filmId: nil
                )
            }
            throw error
        }

        if let diagnosticsTag {
            let bodyPreview = String(data: data.prefix(200), encoding: .utf8) ?? "<binary>"
            PlaybackLogger.log(
                "\(diagnosticsTag) URLSession.data DONE status=\(http.statusCode) bytes=\(data.count) elapsed=\(String(format: "%.2f", Date().timeIntervalSince(networkStarted)))s bodyPreview=\(bodyPreview.prefix(120))",
                filmId: nil
            )
        }

        if http.statusCode == 401, !isRetryAfter401 {
            if let diagnosticsTag {
                PlaybackLogger.log("\(diagnosticsTag) HTTP 401 — refreshing session and retrying once", filmId: nil)
            }
            return try await performRequest(endpoint, timeout: timeout, diagnosticsTag: diagnosticsTag, isRetryAfter401: true)
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

        try validateJSONResponse(data: data, http: http, url: requestURL, diagnosticsTag: diagnosticsTag)

        do {
            return try jsonDecoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    /// Performs a request (e.g. POST) with the signed-in Supabase access token; does not decode a body.
    func performAuthorized(_ request: URLRequest) async throws {
        try await performAuthorizedRequest(request, isRetryAfter401: false)
    }

    private func performAuthorizedRequest(_ original: URLRequest, isRetryAfter401: Bool) async throws {
        var request = original
        let supabaseSession = try await resolveSupabaseSession(forceRefresh: isRetryAfter401, diagnosticsTag: nil)
        request.setValue("Bearer \(supabaseSession.accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }

        if http.statusCode == 401, !isRetryAfter401 {
            try await performAuthorizedRequest(original, isRetryAfter401: true)
            return
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

    /// Returns a valid session, refreshing when expired or when `forceRefresh` is true (401 retry path).
    private func resolveSupabaseSession(forceRefresh: Bool, diagnosticsTag: String?) async throws -> Session {
        let auth = SupabaseManager.shared.client.auth

        if forceRefresh {
            let refreshed = try await auth.refreshSession()
            await syncAuthServiceSession(refreshed)
            if let diagnosticsTag {
                PlaybackLogger.log(
                    "\(diagnosticsTag) Supabase session force-refreshed userId=\(refreshed.user.id.uuidString)",
                    filmId: nil
                )
            }
            return refreshed
        }

        var current = try await auth.session
        if let diagnosticsTag {
            PlaybackLogger.log(
                "\(diagnosticsTag) Supabase client.auth.session OK isExpired=\(current.isExpired) userId=\(current.user.id.uuidString)",
                filmId: nil
            )
            if let meta = AuthTokenDiagnostics.metadata(for: current.accessToken) {
                PlaybackLogger.log("\(diagnosticsTag) client session token \(meta)", filmId: nil)
            }
        }

        if current.isExpired {
            current = try await auth.refreshSession()
            await syncAuthServiceSession(current)
            if let diagnosticsTag {
                PlaybackLogger.log(
                    "\(diagnosticsTag) Supabase session was expired — refreshed before request userId=\(current.user.id.uuidString)",
                    filmId: nil
                )
            }
        }

        return current
    }

    private func syncAuthServiceSession(_ session: Session) async {
        await MainActor.run {
            LiveAppContainer.shared?.sharedAuthService.syncPublishedSession(session)
        }
    }

    private func validateJSONResponse(
        data: Data,
        http: HTTPURLResponse,
        url: String,
        diagnosticsTag: String?
    ) throws {
        let contentType = http.value(forHTTPHeaderField: "Content-Type")?.lowercased() ?? ""
        let hasJSONContentType = contentType.contains("application/json") || contentType.contains("+json")
        let firstByte = data.first { byte in
            byte != 32 && byte != 9 && byte != 10 && byte != 13
        }

        if firstByte == UInt8(ascii: "<") {
            let message = "Expected JSON but got non-JSON response from \(url), status=\(http.statusCode)"
            if let diagnosticsTag {
                PlaybackLogger.log("\(diagnosticsTag) \(message)", filmId: nil)
            }
            throw NetworkError.unexpectedResponse(message)
        }

        if !hasJSONContentType, let firstByte,
           firstByte != UInt8(ascii: "{"), firstByte != UInt8(ascii: "[") {
            let message = "Expected JSON but got non-JSON response from \(url), status=\(http.statusCode)"
            if let diagnosticsTag {
                PlaybackLogger.log("\(diagnosticsTag) \(message)", filmId: nil)
            }
            throw NetworkError.unexpectedResponse(message)
        }
    }

    private static func timedSession(requestTimeout: TimeInterval) -> URLSession {
        timedSessionsLock.lock()
        defer { timedSessionsLock.unlock() }
        if let existing = timedSessions[requestTimeout] {
            return existing
        }
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = requestTimeout
        config.timeoutIntervalForResource = requestTimeout
        config.waitsForConnectivity = false
        let created = URLSession(configuration: config)
        timedSessions[requestTimeout] = created
        return created
    }
}
