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

    func fetchPlaybackURL(filmId: Int) async throws -> URL {
        PlaybackLogger.log("S3SignedURLService.fetchPlaybackURL START", filmId: filmId)
        if let cached = cachedURL(for: filmId) {
            PlaybackLogger.log("cache HIT url=\(PlaybackLogger.redactedURL(cached))", filmId: filmId)
            return cached
        }
        PlaybackLogger.log("cache MISS — requesting signed URL from API", filmId: filmId)

        // Production serves playback signing at presign-upload; presigned-playback may be absent.
        let endpoints: [Endpoint] = [
            .presignUpload(filmId: filmId),
            .presignedPlaybackURL(filmId: filmId)
        ]

        var lastError: Error = NetworkError.unknown
        for endpoint in endpoints {
            let endpointName = Self.endpointName(for: endpoint)
            do {
                let request = try endpoint.urlRequest()
                PlaybackLogger.log(
                    "API request START endpoint=\(endpointName) url=\(request.url?.absoluteString ?? "?")",
                    filmId: filmId
                )
                let response: SignedPlaybackURLResponse = try await APIClient.shared.request(endpoint)
                PlaybackLogger.log("API request SUCCESS endpoint=\(endpointName)", filmId: filmId)
                guard let raw = response.resolvedURLString else {
                    PlaybackLogger.log(
                        "API response missing URL fields endpoint=\(endpointName) raw=\(String(describing: response))",
                        filmId: filmId
                    )
                    lastError = NetworkError.unknown
                    continue
                }
                guard let url = PlaybackURLNormalizer.url(from: raw) else {
                    PlaybackLogger.log(
                        "API response URL failed normalization endpoint=\(endpointName) raw=\(raw.prefix(120))",
                        filmId: filmId
                    )
                    lastError = NetworkError.unknown
                    continue
                }
                storeCachedURL(url, for: filmId)
                PlaybackLogger.log(
                    "resolved signed URL endpoint=\(endpointName) url=\(PlaybackLogger.redactedURL(url))",
                    filmId: filmId
                )
                return url
            } catch NetworkError.unauthorized {
                PlaybackLogger.log("API request UNAUTHORIZED endpoint=\(endpointName)", filmId: filmId)
                lastError = PlaybackError.signInRequired
            } catch NetworkError.notFound {
                PlaybackLogger.log("API request NOT FOUND endpoint=\(endpointName)", filmId: filmId)
                continue
            } catch NetworkError.decodingError(let underlying) {
                PlaybackLogger.logError(
                    "API response DECODING FAILED endpoint=\(endpointName)",
                    error: underlying,
                    filmId: filmId
                )
                continue
            } catch {
                PlaybackLogger.logError("API request FAILED endpoint=\(endpointName)", error: error, filmId: filmId)
                lastError = error
            }
        }
        PlaybackLogger.logError("S3SignedURLService.fetchPlaybackURL FAILED — all endpoints exhausted", error: lastError, filmId: filmId)
        throw lastError
    }

    private static func endpointName(for endpoint: Endpoint) -> String {
        switch endpoint {
        case .presignUpload: return "presign-upload"
        case .presignedPlaybackURL: return "presigned-playback"
        case .recordIAPPurchase: return "record-iap-purchase"
        case .sendTicketEmail: return "send-ticket-email"
        }
    }

    func invalidateCache(filmId: Int) {
        removeCachedURL(for: filmId)
    }
}
