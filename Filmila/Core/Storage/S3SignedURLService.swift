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
        if let cached = cachedURL(for: filmId) {
            return cached
        }

        // Production serves playback signing at presign-upload; presigned-playback may be absent.
        let endpoints: [Endpoint] = [
            .presignUpload(filmId: filmId),
            .presignedPlaybackURL(filmId: filmId)
        ]

        var lastError: Error = NetworkError.unknown
        for endpoint in endpoints {
            do {
                let response: SignedPlaybackURLResponse = try await APIClient.shared.request(endpoint)
                guard let raw = response.resolvedURLString,
                      let url = PlaybackURLNormalizer.url(from: raw) else {
                    lastError = NetworkError.unknown
                    continue
                }
                storeCachedURL(url, for: filmId)
                print("[FilmilaPlayback] signed URL for filmId=\(filmId)")
                return url
            } catch NetworkError.unauthorized {
                lastError = PlaybackError.signInRequired
            } catch NetworkError.notFound {
                continue
            } catch NetworkError.decodingError {
                continue
            } catch {
                lastError = error
            }
        }
        throw lastError
    }

    func invalidateCache(filmId: Int) {
        removeCachedURL(for: filmId)
    }
}
