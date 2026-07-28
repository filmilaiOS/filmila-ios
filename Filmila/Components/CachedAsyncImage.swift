import SwiftUI
import UIKit

// MARK: - Memory cache (serialized access around NSCache for explicit thread safety)

final class FilmilaImageMemoryCache: @unchecked Sendable {
    static let shared = FilmilaImageMemoryCache()

    private let lock = NSLock()
    private let cache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 100
        c.totalCostLimit = 50 * 1024 * 1024
        return c
    }()

    private init() {}

    func image(forKey key: String) -> UIImage? {
        lock.lock()
        defer { lock.unlock() }
        return cache.object(forKey: key as NSString)
    }

    func insert(_ image: UIImage, forKey key: String) {
        let cost = Self.estimatedByteCost(for: image)
        lock.lock()
        defer { lock.unlock() }
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }

    private static func estimatedByteCost(for image: UIImage) -> Int {
        if let cg = image.cgImage {
            return cg.bytesPerRow * cg.height
        }
        let w = Int(image.size.width * image.scale)
        let h = Int(image.size.height * image.scale)
        return max(1, w * h * 4)
    }
}

// MARK: - URLSession + on-disk URLCache (persists between launches)

enum FilmilaImageURLSession {
    static let shared: URLSession = {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let diskDir = caches[0].appendingPathComponent("FilmilaImageURLCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: diskDir, withIntermediateDirectories: true)

        let urlCache = URLCache(
            memoryCapacity: 12 * 1024 * 1024,
            diskCapacity: 80 * 1024 * 1024,
            directory: diskDir
        )
        let config = URLSessionConfiguration.default
        config.urlCache = urlCache
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config)
    }()
}

// MARK: - View

struct CachedAsyncImage: View {
    /// Remote image URL string (`http` / `https` only).
    let url: String?
    var contentMode: ContentMode = .fill

    @State private var loadedImage: UIImage?
    @State private var didFail = false

    private var normalizedURLString: String? {
        guard let raw = url?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        return raw
    }

    private var remoteURL: URL? {
        guard let normalizedURLString,
              let u = URL(string: normalizedURLString),
              let scheme = u.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else { return nil }
        return u
    }

    private var showPlaceholder: Bool {
        normalizedURLString == nil || remoteURL == nil || didFail
    }

    private var showShimmer: Bool {
        remoteURL != nil && loadedImage == nil && !didFail
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let loadedImage {
                    Image(uiImage: loadedImage)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                } else if showPlaceholder {
                    placeholder
                } else if showShimmer {
                    LoadingShimmer(width: geo.size.width, height: geo.size.height, cornerRadius: 0)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .task(id: normalizedURLString) {
            await loadIfNeeded()
        }
    }

    private var placeholder: some View {
        ZStack {
            FilmilaColors.surface
            Image(systemName: "film.fill")
                .font(.filmilaIconPlaceholder)
                .foregroundStyle(FilmilaColors.textSecondary.opacity(0.4))
        }
    }

    private func loadIfNeeded() async {
        await MainActor.run {
            loadedImage = nil
            didFail = false
        }

        guard let key = normalizedURLString else {
            return
        }
        guard let remoteURL = Self.remoteHTTPURL(from: key) else {
            await MainActor.run { didFail = true }
            return
        }

        if let memoryHit = FilmilaImageMemoryCache.shared.image(forKey: key) {
            await MainActor.run { loadedImage = memoryHit }
            return
        }

        do {
            let (data, _) = try await FilmilaImageURLSession.shared.data(from: remoteURL)
            try Task.checkCancellation()
            guard let image = UIImage(data: data) else {
                await MainActor.run { didFail = true }
                return
            }
            FilmilaImageMemoryCache.shared.insert(image, forKey: key)
            await MainActor.run { loadedImage = image }
        } catch is CancellationError {
            return
        } catch {
            await MainActor.run { didFail = true }
        }
    }

    /// Same rules as `remoteURL` for use from `loadIfNeeded` without capturing changing view state mid-flight.
    private static func remoteHTTPURL(from string: String) -> URL? {
        guard let u = URL(string: string),
              let scheme = u.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else { return nil }
        return u
    }
}

#if DEBUG
#Preview {
    CachedAsyncImage(url: "https://picsum.photos/400/600")
        .frame(width: 120, height: 180)
        .clipped()
}
#endif
