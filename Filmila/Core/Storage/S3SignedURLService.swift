import Foundation

protocol S3SignedURLServiceProtocol: AnyObject {
    func fetchPlaybackURL(filmId: Int) async throws -> URL
    func invalidateCache(filmId: Int)
}

private struct PresignUploadResponse: Decodable {
    let playbackURL: String

    enum CodingKeys: String, CodingKey {
        case playbackURL = "url"
    }
}

final class S3SignedURLService: S3SignedURLServiceProtocol {
    private let lock = NSLock()
    private var cache: [Int: (url: URL, expiresAt: Date)] = [:]
    private let ttlSeconds: TimeInterval = 600
    private let minimumRemainingSeconds: TimeInterval = 60

    func fetchPlaybackURL(filmId: Int) async throws -> URL {
        lock.lock()
        if let entry = cache[filmId], entry.expiresAt > Date().addingTimeInterval(minimumRemainingSeconds) {
            let url = entry.url
            lock.unlock()
            return url
        }
        lock.unlock()

        let response: PresignUploadResponse = try await APIClient.shared.request(.presignUpload(filmId: filmId))
        guard let url = URL(string: response.playbackURL) else {
            throw NetworkError.unknown
        }

        lock.lock()
        cache[filmId] = (url: url, expiresAt: Date().addingTimeInterval(ttlSeconds))
        lock.unlock()
        return url
    }

    func invalidateCache(filmId: Int) {
        lock.lock()
        cache.removeValue(forKey: filmId)
        lock.unlock()
    }
}
