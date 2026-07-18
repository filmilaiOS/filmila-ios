import AVFoundation
import Foundation

/// Diagnostic logging for the video playback pipeline. Filter Xcode console with `FilmilaPlayback`.
enum PlaybackLogger {
    private static let prefix = "[FilmilaPlayback]"

    static func log(_ message: String, filmId: Int? = nil) {
        if let filmId {
            print("\(prefix) [filmId=\(filmId)] \(message)")
        } else {
            print("\(prefix) \(message)")
        }
    }

    static func logError(_ message: String, error: Error?, filmId: Int? = nil) {
        log("\(message): \(error?.localizedDescription ?? "nil")", filmId: filmId)
        logNSError(context: message, error: error, filmId: filmId)
    }

    static func logNSError(context: String, error: Error?, filmId: Int? = nil) {
        guard let error else { return }
        let ns = error as NSError
        log(
            "\(context) NSError domain=\(ns.domain) code=\(ns.code) userInfo=\(ns.userInfo)",
            filmId: filmId
        )
        if let underlying = ns.userInfo[NSUnderlyingErrorKey] as? Error {
            let underlyingNS = underlying as NSError
            log(
                "\(context) underlying domain=\(underlyingNS.domain) code=\(underlyingNS.code) desc=\(underlyingNS.localizedDescription)",
                filmId: filmId
            )
        }
    }

    static func playerItemStatus(_ status: AVPlayerItem.Status) -> String {
        switch status {
        case .unknown: return "unknown"
        case .readyToPlay: return "readyToPlay"
        case .failed: return "failed"
        @unknown default: return "unknown(\(status.rawValue))"
        }
    }

    static func timeControlStatus(_ status: AVPlayer.TimeControlStatus) -> String {
        switch status {
        case .paused: return "paused"
        case .waitingToPlayAtSpecifiedRate: return "waitingToPlayAtSpecifiedRate"
        case .playing: return "playing"
        @unknown default: return "unknown(\(status.rawValue))"
        }
    }

    static func waitingReason(_ reason: AVPlayer.WaitingReason?) -> String {
        reason?.rawValue ?? "nil"
    }

    static func redactedURL(_ url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url.absoluteString
        }
        if components.query != nil {
            components.query = "<redacted>"
        }
        return components.string ?? url.absoluteString
    }
}
