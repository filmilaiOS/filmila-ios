import Foundation

enum ISO8601DateParsing {
    private static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let internetDateTime: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func date(from string: String) -> Date? {
        withFractionalSeconds.date(from: string) ?? internetDateTime.date(from: string)
    }
}

extension KeyedDecodingContainer where K: CodingKey {
    func decodeLossyDouble(forKey key: K) throws -> Double {
        if let value = try? decode(Double.self, forKey: key) {
            return value
        }
        if let intValue = try? decode(Int.self, forKey: key) {
            return Double(intValue)
        }
        if let string = try? decode(String.self, forKey: key), let parsed = Double(string) {
            return parsed
        }
        return try decode(Double.self, forKey: key)
    }

    func decodeFilmilaTimestamp(forKey key: K) throws -> Date {
        if let date = try? decode(Date.self, forKey: key) {
            return date
        }
        let string = try decode(String.self, forKey: key)
        guard let date = ISO8601DateParsing.date(from: string) else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: self,
                debugDescription: "Invalid ISO8601 date: \(string)"
            )
        }
        return date
    }

    func decodeFilmilaTimestampIfPresent(forKey key: K) throws -> Date? {
        guard contains(key) else { return nil }
        if try decodeNil(forKey: key) {
            return nil
        }
        if let date = try? decode(Date.self, forKey: key) {
            return date
        }
        let string = try decode(String.self, forKey: key)
        guard let date = ISO8601DateParsing.date(from: string) else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: self,
                debugDescription: "Invalid ISO8601 date: \(string)"
            )
        }
        return date
    }
}
