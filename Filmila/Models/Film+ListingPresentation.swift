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

    /// Catalog `filmmaker` is often an account email. Show a name only.
    var publicFilmmakerDisplayName: String? {
        guard let raw = filmmaker?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        if raw.contains("@") {
            return nil
        }
        return raw
    }

    /// Maps known catalog genre keys through the same localization table as Search.
    var localizedGenreLabel: String? {
        guard let raw = genre?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        return Self.localizedGenreName(raw)
    }

    static func localizedGenreName(_ raw: String) -> String {
        switch raw.lowercased() {
        case "drama":
            String(localized: "genre_drama")
        case "comedy":
            String(localized: "genre_comedy")
        case "documentary":
            String(localized: "genre_documentary")
        case "animation":
            String(localized: "genre_animation")
        case "horror":
            String(localized: "genre_horror")
        case "romance":
            String(localized: "genre_romance")
        case "thriller":
            String(localized: "genre_thriller")
        default:
            raw
        }
    }
}
