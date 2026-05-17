import Foundation

extension Film {
    /// Human-readable duration for listings and hero (matches detail copy).
    var formattedDurationForListing: String? {
        guard let seconds = duration, seconds > 0 else { return nil }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return String(format: String(localized: "detail_duration_hm"), hours, minutes)
        }
        return String(format: String(localized: "detail_duration_m"), minutes)
    }

    static func formattedAverageRating(_ average: Double) -> String {
        String(format: "%.1f", average)
    }
}
