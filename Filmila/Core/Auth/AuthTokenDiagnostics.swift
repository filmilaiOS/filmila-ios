import Foundation

/// Decodes Supabase JWT metadata for playback/API diagnostics (never logs full tokens).
enum AuthTokenDiagnostics {
    struct JWTMetadata: CustomStringConvertible {
        let sub: String?
        let role: String?
        let issuedAt: Date?
        let expiresAt: Date?
        let isExpired: Bool
        let tokenPrefix: String

        var description: String {
            let iat = issuedAt.map { ISO8601DateFormatter().string(from: $0) } ?? "nil"
            let exp = expiresAt.map { ISO8601DateFormatter().string(from: $0) } ?? "nil"
            return "prefix=\(tokenPrefix) sub=\(sub ?? "nil") role=\(role ?? "nil") iat=\(iat) exp=\(exp) expired=\(isExpired)"
        }
    }

    static func metadata(for token: String?, now: Date = Date()) -> JWTMetadata? {
        guard let token, !token.isEmpty else { return nil }
        let prefix = String(token.prefix(12))
        guard let payload = decodeJWTPayload(token) else {
            return JWTMetadata(
                sub: nil,
                role: nil,
                issuedAt: nil,
                expiresAt: nil,
                isExpired: false,
                tokenPrefix: prefix
            )
        }

        let exp = payload["exp"] as? TimeInterval
        let iat = payload["iat"] as? TimeInterval
        let expiresAt = exp.map { Date(timeIntervalSince1970: $0) }
        let issuedAt = iat.map { Date(timeIntervalSince1970: $0) }
        let isExpired = expiresAt.map { now >= $0 } ?? false

        let sub = payload["sub"] as? String
        let role = (payload["role"] as? String)
            ?? (payload["app_metadata"] as? [String: Any])?["role"] as? String
            ?? (payload["user_metadata"] as? [String: Any])?["role"] as? String

        return JWTMetadata(
            sub: sub,
            role: role,
            issuedAt: issuedAt,
            expiresAt: expiresAt,
            isExpired: isExpired,
            tokenPrefix: prefix
        )
    }

    static func describeAuthorizationHeader(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "Authorization=<missing>" }
        if value.hasPrefix("Bearer ") {
            let token = String(value.dropFirst("Bearer ".count))
            if let meta = metadata(for: token) {
                return "Authorization=Bearer (\(meta))"
            }
            return "Authorization=Bearer tokenLen=\(token.count) prefix=\(token.prefix(12))..."
        }
        return "Authorization=non-Bearer format len=\(value.count) prefix=\(value.prefix(16))..."
    }

    static func tokensMatch(_ a: String?, _ b: String?) -> Bool {
        guard let a, let b, !a.isEmpty, !b.isEmpty else { return false }
        return a == b
    }

    private static func decodeJWTPayload(_ token: String) -> [String: Any]? {
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        var base64 = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padding = (4 - base64.count % 4) % 4
        if padding > 0 { base64 += String(repeating: "=", count: padding) }
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
    }
}
