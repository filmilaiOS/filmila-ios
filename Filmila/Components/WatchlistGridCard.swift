import SwiftUI

struct WatchlistGridCard: View {
    let film: Film
    var averageRating: Double?
    var width: CGFloat
    var onRemove: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            FilmPosterCard(
                film: film,
                width: width,
                averageRating: averageRating
            )

            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(FilmilaColors.textMuted)
                        .frame(width: 44, height: 44)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(String(localized: "detail_watchlist_remove")))
            }
        }
        .frame(width: width, alignment: .topLeading)
    }
}

#if DEBUG
#Preview {
    WatchlistGridCard(
        film: Film(
            id: 1,
            title: "Nour of Riyadh",
            thumbnailUrl: "https://picsum.photos/400/600",
            price: 18,
            status: .approved,
            genre: "Drama",
            duration: 1080,
            viewCount: 0,
            filmmaker: "Nora Al-Dossary",
            createdAt: Date()
        ),
        averageRating: 4.9,
        width: 170
    )
    .padding()
    .background(FilmilaColors.background)
    .preferredColorScheme(.dark)
}
#endif
