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
        diagnosticsTag: String?
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

        var attachedToken: String?
        var sessionFetchError: Error?
        var supabaseSessionExpired: Bool?

        do {
            let session = try await SupabaseManager.shared.client.auth.session
            supabaseSessionExpired = session.isExpired
            attachedToken = session.accessToken
            if let diagnosticsTag {
                PlaybackLogger.log(
                    "\(diagnosticsTag) Supabase client.auth.session OK isExpired=\(session.isExpired) userId=\(session.user.id.uuidString)",
                    filmId: nil
                )
                if let meta = AuthTokenDiagnostics.metadata(for: session.accessToken) {
                    PlaybackLogger.log("\(diagnosticsTag) client session token \(meta)", filmId: nil)
                }
            }
        } catch {
            sessionFetchError = error
            if let diagnosticsTag {
                PlaybackLogger.logError("\(diagnosticsTag) Supabase client.auth.session FAILED", error: error, filmId: nil)
            }
        }

        if let attachedToken, !attachedToken.isEmpty {
            request.setValue("Bearer \(attachedToken)", forHTTPHeaderField: "Authorization")
        } else if let diagnosticsTag {
            PlaybackLogger.log(
                "\(diagnosticsTag) NO Supabase access_token attached — request may use keychain bearer only or be anonymous",
                filmId: nil
            )
        }

        let finalAuth = request.value(forHTTPHeaderField: "Authorization")
        if let diagnosticsTag {
            PlaybackLogger.log(
                "\(diagnosticsTag) Authorization header SENT: \(AuthTokenDiagnostics.describeAuthorizationHeader(finalAuth))",
                filmId: nil
            )
            if supabaseSessionExpired == true {
                PlaybackLogger.log(
                    "\(diagnosticsTag) WARNING Supabase session.isExpired=true — token may be rejected with 401 until refreshSession runs",
                    filmId: nil
                )
            }
            if sessionFetchError != nil, keychainAuthBefore == nil {
                PlaybackLogger.log("\(diagnosticsTag) WARNING no auth token available for this request", filmId: nil)
            }
        }

        if let diagnosticsTag {
            PlaybackLogger.log("\(diagnosticsTag) URLSession.data START method=\(request.httpMethod ?? "GET") url=\(requestURL)", filmId: nil)
        }

        let activeSession = timeout.map { Self.timedSession(requestTimeout: $0) } ?? session
        let networkStarted = Date()

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await activeSession.data(for: request)
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

        guard let http = response as? HTTPURLResponse else {
            if let diagnosticsTag {
                PlaybackLogger.log("\(diagnosticsTag) URLSession.data DONE non-HTTP response", filmId: nil)
            }
            throw NetworkError.unknown
        }

        if let diagnosticsTag {
            let bodyPreview = String(data: data.prefix(200), encoding: .utf8) ?? "<binary>"
            PlaybackLogger.log(
                "\(diagnosticsTag) URLSession.data DONE status=\(http.statusCode) bytes=\(data.count) elapsed=\(String(format: "%.2f", Date().timeIntervalSince(networkStarted)))s bodyPreview=\(bodyPreview.prefix(120))",
                filmId: nil
            )
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
