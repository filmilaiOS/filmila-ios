import SwiftUI

struct SearchResultRowCard: View {
    let film: Film

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            CachedAsyncImage(url: film.thumbnailUrl)
                .frame(width: FilmListingPosterMetrics.rowWidth, height: FilmListingPosterMetrics.rowHeight)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(film.displayTitle)
                    .font(.filmilaBodyMedium)
                    .foregroundStyle(FilmilaColors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let filmmaker = film.publicFilmmakerDisplayName {
                    Text(filmmaker)
                        .font(.filmilaCaption)
                        .foregroundStyle(FilmilaColors.textSecondary)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    if let genre = film.localizedGenreLabel {
                        Text(genre)
                            .lineLimit(1)
                    }
                    if film.localizedGenreLabel != nil, film.formattedDurationForListing != nil {
                        Text("•")
                            .foregroundStyle(FilmilaColors.textMuted)
                    }
                    if let duration = film.formattedDurationForListing {
                        Text(duration)
                            .lineLimit(1)
                    }
                }
                .font(.filmilaCaptionMd)
                .foregroundStyle(FilmilaColors.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(Spacing.md)
        .background(FilmilaColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(FilmilaColors.cardBorder, lineWidth: 1)
        )
    }
}

#if DEBUG
#Preview {
    SearchResultRowCard(
        film: Film(
            id: 1,
            title: "Nour of Riyadh",
            thumbnailUrl: "https://picsum.photos/200",
            price: 18,
            status: .approved,
            genre: "Drama",
            duration: 1080,
            viewCount: 0,
            filmmaker: "Nora Al-Dossary",
            createdAt: Date()
        )
    )
    .padding()
    .background(FilmilaColors.background)
    .preferredColorScheme(.dark)
}
#endif
