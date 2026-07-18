import Foundation

protocol S3SignedURLServiceProtocol: AnyObject {
    func fetchPlaybackURL(filmId: Int) async throws -> URL
    func invalidateCache(filmId: Int)
}

private struct SignedPlaybackURLResponse: Decodable {
    let url: String?
    let playbackUrl: String?
    let signedUrl: String?
    let signedURL: String?

    var resolvedURLString: String? {
        for candidate in [url, playbackUrl, signedUrl, signedURL] {
            guard let candidate, !candidate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            return candidate
        }
        return nil
    }
}

final class S3SignedURLService: S3SignedURLServiceProtocol {
    /// Caps auth + network + decode for each signing endpoint attempt.
    private static let signingRequestTimeout: TimeInterval = 20

    private let cacheLock = NSLock()
    private var cache: [Int: (url: URL, expiresAt: Date)] = [:]
    private let ttlSeconds: TimeInterval = 600
    private let minimumRemainingSeconds: TimeInterval = 60

    private func cachedURL(for filmId: Int) -> URL? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        guard let entry = cache[filmId],
              entry.expiresAt > Date().addingTimeInterval(minimumRemainingSeconds) else {
            return nil
        }
        return entry.url
    }

    private func storeCachedURL(_ url: URL, for filmId: Int) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        cache[filmId] = (url: url, expiresAt: Date().addingTimeInterval(ttlSeconds))
    }

    private func removeCachedURL(for filmId: Int) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        cache.removeValue(forKey: filmId)
    }

    /// Requests a time-limited signed playback URL from the Filmila backend (`GET /api/presign-upload?filmId=`).
    /// The catalog `video_url` is a private S3 object key; this endpoint returns a presigned GET URL for AVPlayer.
    /// presigned-playback fallback removed — that route is not deployed on production.
    func fetchPlaybackURL(filmId: Int) async throws -> URL {
        PlaybackLogger.log("S3SignedURLService.fetchPlaybackURL ENTER", filmId: filmId)
        if let cached = cachedURL(for: filmId) {
            PlaybackLogger.log("cache HIT url=\(PlaybackLogger.redactedURL(cached))", filmId: filmId)
            return cached
        }
        PlaybackLogger.log("cache MISS — will call presign-upload", filmId: filmId)

        let endpoint = Endpoint.presignUpload(filmId: filmId)
        let diagnosticsTag = "S3SignedURL[presign-upload]"

        let request = try endpoint.urlRequest()
        let exactURL = request.url?.absoluteString ?? "?"
        PlaybackLogger.log(
            "signing endpoint READY method=\(request.httpMethod ?? "GET") url=\(exactURL) timeout=\(Self.signingRequestTimeout)s",
            filmId: filmId
        )
        PlaybackLogger.log("calling APIClient.request NOW", filmId: filmId)

        await logAuthServiceTokenComparison(diagnosticsTag: diagnosticsTag, filmId: filmId)

        do {
            let response: SignedPlaybackURLResponse = try await APIClient.shared.request(
                endpoint,
                timeout: Self.signingRequestTimeout,
                diagnosticsTag: diagnosticsTag
            )

            PlaybackLogger.log("APIClient.request RETURNED endpoint=presign-upload", filmId: filmId)
            guard let raw = response.resolvedURLString else {
                PlaybackLogger.log("API response missing URL fields endpoint=presign-upload", filmId: filmId)
                throw NetworkError.unknown
            }
            guard let url = PlaybackURLNormalizer.url(from: raw) else {
                PlaybackLogger.log(
                    "API response URL failed normalization endpoint=presign-upload raw=\(raw.prefix(120))",
                    filmId: filmId
                )
                throw NetworkError.unknown
            }
            storeCachedURL(url, for: filmId)
            PlaybackLogger.log(
                "resolved signed URL endpoint=presign-upload url=\(PlaybackLogger.redactedURL(url))",
                filmId: filmId
            )
            return url
        } catch NetworkError.timeout {
            PlaybackLogger.log(
                "signing request TIMED OUT endpoint=presign-upload url=\(exactURL)",
                filmId: filmId
            )
            throw PlaybackError.signingTimeout
        } catch NetworkError.unauthorized {
            PlaybackLogger.log("API request UNAUTHORIZED endpoint=presign-upload", filmId: filmId)
            throw PlaybackError.signInRequired
        } catch is CancellationError {
            PlaybackLogger.log(
                "signing request CANCELLED (likely timeout) endpoint=presign-upload",
                filmId: filmId
            )
            throw PlaybackError.signingTimeout
        } catch let urlError as URLError where urlError.code == .timedOut {
            PlaybackLogger.logError(
                "signing request URLSession TIMED OUT endpoint=presign-upload",
                error: urlError,
                filmId: filmId
            )
            throw PlaybackError.signingTimeout
        } catch {
            PlaybackLogger.logError(
                "API request FAILED endpoint=presign-upload url=\(exactURL)",
                error: error,
                filmId: filmId
            )
            throw error
        }
    }

    func invalidateCache(filmId: Int) {
        removeCachedURL(for: filmId)
    }

    /// Logs `AuthService.currentToken` (UI/published session) vs Supabase client session for 401 diagnosis.
    @MainActor
    private func logAuthServiceTokenComparison(diagnosticsTag: String, filmId: Int) async {
        guard let container = LiveAppContainer.shared else {
            PlaybackLogger.log("\(diagnosticsTag) AuthService comparison skipped — LiveAppContainer unavailable", filmId: filmId)
            return
        }
        let publishedToken = container.authService.currentToken
        if let meta = AuthTokenDiagnostics.metadata(for: publishedToken) {
            PlaybackLogger.log("\(diagnosticsTag) AuthService.currentToken (published session copy) \(meta)", filmId: filmId)
        } else {
            PlaybackLogger.log("\(diagnosticsTag) AuthService.currentToken nil/empty", filmId: filmId)
        }

        do {
            let clientSession = try await SupabaseManager.shared.client.auth.session
            let clientToken = clientSession.accessToken
            if let meta = AuthTokenDiagnostics.metadata(for: clientToken) {
                PlaybackLogger.log("\(diagnosticsTag) Supabase client session token (used by APIClient) \(meta)", filmId: filmId)
            }
            let match = AuthTokenDiagnostics.tokensMatch(publishedToken, clientToken)
            PlaybackLogger.log(
                "\(diagnosticsTag) AuthService token matches Supabase client token: \(match) client.isExpired=\(clientSession.isExpired)",
                filmId: filmId
            )
        } catch {
            PlaybackLogger.logError("\(diagnosticsTag) Supabase client session read for comparison FAILED", error: error, filmId: filmId)
        }
    }
}
