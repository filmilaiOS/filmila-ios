import Foundation

enum PlaybackURLNormalizer {
    /// Parses a playback URL string from the signing API (trims, strips stray quotes, adds https if needed).
    static func url(from raw: String) -> URL? {
        var trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("\""), trimmed.hasSuffix("\""), trimmed.count >= 2 {
            trimmed = String(trimmed.dropFirst().dropLast())
        }
        guard !trimmed.isEmpty else { return nil }
        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }
        if trimmed.hasPrefix("//") {
            return URL(string: "https:" + trimmed)
        }
        if !trimmed.contains("://") {
            return URL(string: "https://" + trimmed)
        }
        return nil
    }

    /// Short-lived S3 presigned query params — AVPlayer must request a fresh signed URL.
    static func isExpiringSignedS3URL(_ url: URL) -> Bool {
        let absolute = url.absoluteString.lowercased()
        if absolute.contains("x-amz-signature")
            || absolute.contains("x-amz-algorithm")
            || absolute.contains("x-amz-expires")
            || absolute.contains("x-amz-credential") {
            return true
        }
        guard let host = url.host?.lowercased() else { return false }
        return host.contains("amazonaws.com") && url.query != nil
    }

    /// Private bucket object keys stored in `video_url` must be signed before playback.
    static func requiresPlaybackSigning(_ url: URL) -> Bool {
        if isExpiringSignedS3URL(url) { return true }
        guard let host = url.host?.lowercased() else { return false }
        return host.contains("amazonaws.com") || host.hasSuffix(".s3.amazonaws.com")
    }
}

extension Film {
    /// Stable public stream URL (CDN/HLS manifest), not a private or expiring S3 object key.
    var directPlaybackURL: URL? {
        for candidate in [hlsUrl, videoUrl] {
            guard let raw = candidate?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !raw.isEmpty,
                  let url = PlaybackURLNormalizer.url(from: raw),
                  !PlaybackURLNormalizer.requiresPlaybackSigning(url) else { continue }
            return url
        }
        return nil
    }
}
