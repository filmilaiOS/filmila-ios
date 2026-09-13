#if DEBUG
import SwiftUI

enum FilmPriceBadge {
    static func label(for film: Film) -> String {
        if film.isFree {
            return "Free"
        }
        return formattedSAR(film.price)
    }

    /// Display-only SAR formatting. Whole riyals omit `.00`; fractional amounts keep two decimals.
    static func formattedSAR(_ price: Double) -> String {
        let cents = (price * 100).rounded()
        if cents.truncatingRemainder(dividingBy: 100) == 0 {
            return String(format: "SAR %d", Int(cents / 100))
        }
        return String(format: "SAR %.2f", price)
    }
}

struct FilmPricePill: View {
    let film: Film
    var compact: Bool = false

    var body: some View {
        Text(FilmPriceBadge.label(for: film))
            .font(compact ? .filmilaCapsBadge : .filmilaCaptionMd)
            .foregroundStyle(film.isFree ? FilmilaColors.textPrimary : FilmilaColors.accent)
            .padding(.horizontal, compact ? 8 : 10)
            .padding(.vertical, compact ? 4 : 5)
            .background(
                Capsule(style: .continuous)
                    .fill(film.isFree ? FilmilaColors.posterBadgeBackdrop : FilmilaColors.accentSubtle)
            )
    }
}
#endif

