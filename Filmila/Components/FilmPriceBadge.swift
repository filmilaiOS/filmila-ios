import SwiftUI

enum FilmPriceBadge {
    static func label(for film: Film) -> String {
        if film.isFree {
            return String(localized: "price_free_short")
        }
        return String(format: String(localized: "price_sar_format"), film.price)
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
