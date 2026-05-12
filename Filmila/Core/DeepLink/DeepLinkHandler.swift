import Combine
import Foundation
import Supabase

protocol DeepLinkHandlerProtocol: AnyObject, ObservableObject {
    var pendingRoute: DeepLinkRoute? { get set }
    func handle(_ url: URL)
}

final class DeepLinkHandler: DeepLinkHandlerProtocol, ObservableObject {
    @Published var pendingRoute: DeepLinkRoute?

    func handle(_ url: URL) {
        Task {
            try? await SupabaseManager.shared.client.auth.session(from: url)
            let route = Self.parseRoute(from: url)
            await MainActor.run {
                self.pendingRoute = route
            }
        }
    }

    /// Parses filmila.com / `filmila://` routes. Hosts: `filmila.com`, `www.filmila.com`; scheme `filmila` as fallback.
    static func parseRoute(from url: URL) -> DeepLinkRoute? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let scheme = (components.scheme ?? "").lowercased()
        let host = (components.host ?? "").lowercased()
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let segments = path.split(separator: "/").map(String.init)

        let isFilmilaHost = host == "filmila.com" || host == "www.filmila.com" || host.hasSuffix(".filmila.com")
        let isFilmilaScheme = scheme == "filmila"
        let isHttpFamily = scheme == "https" || scheme == "http"

        guard isFilmilaScheme || (isHttpFamily && isFilmilaHost) else {
            return nil
        }

        if isFilmilaScheme {
            if host == "films", let id = segments.first.flatMap(Int.init) {
                return .filmDetail(filmId: id)
            }
            if host == "profile", segments.isEmpty {
                return .profile
            }
            if host == "payment", segments.first == "callback" {
                let orderId = components.queryItems?.first(where: { $0.name == "orderId" })?.value
                    ?? components.queryItems?.first(where: { $0.name == "order_id" })?.value
                if let orderId, !orderId.isEmpty {
                    return .paymentCallback(orderId: orderId)
                }
                return nil
            }
            if host == "search" {
                let q = components.queryItems?.first(where: { $0.name == "q" })?.value
                    ?? components.queryItems?.first(where: { $0.name == "query" })?.value
                return .search(query: q)
            }
        }

        if segments.first == "films", segments.count >= 2, let id = Int(segments[1]) {
            return .filmDetail(filmId: id)
        }

        if segments.first == "payment", segments.count >= 2, segments[1] == "callback" {
            let orderId = components.queryItems?.first(where: { $0.name == "orderId" })?.value
                ?? components.queryItems?.first(where: { $0.name == "order_id" })?.value
            if let orderId, !orderId.isEmpty {
                return .paymentCallback(orderId: orderId)
            }
            return nil
        }

        if segments.first == "profile", segments.count == 1 {
            return .profile
        }

        if segments.first == "search" {
            let q = components.queryItems?.first(where: { $0.name == "q" })?.value
                ?? components.queryItems?.first(where: { $0.name == "query" })?.value
            return .search(query: q)
        }

        return nil
    }
}
