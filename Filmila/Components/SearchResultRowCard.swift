import SwiftUI

struct SearchResultRowCard: View {
    let film: Film
    var thumbnailSize: CGFloat = 72

    var body: some View {
        HStack(spacing: Spacing.md) {
            CachedAsyncImage(url: film.thumbnailUrl)
                .frame(width: thumbnailSize, height: thumbnailSize)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(film.displayTitle)
                    .font(.filmilaBodyMedium)
                    .foregroundStyle(FilmilaColors.textPrimary)
                    .lineLimit(1)

                if let filmmaker = film.filmmaker?.trimmingCharacters(in: .whitespacesAndNewlines), !filmmaker.isEmpty {
                    Text(filmmaker)
                        .font(.filmilaCaption)
                        .foregroundStyle(FilmilaColors.textSecondary)
                        .lineLimit(1)
                }

                Text(FilmPriceBadge.label(for: film))
                    .font(.filmilaCaptionMd)
                    .foregroundStyle(FilmilaColors.accent)
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
