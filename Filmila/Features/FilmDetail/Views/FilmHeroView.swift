import SwiftUI

struct FilmHeroView: View {
    let film: Film

    private var yearText: String {
        String(Calendar.current.component(.year, from: film.createdAt))
    }

    private var durationText: String? {
        film.formattedDurationForListing
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            CachedAsyncImage(url: film.thumbnailUrl)
                .aspectRatio(16 / 9, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipped()

            LinearGradient(
                colors: [.clear, FilmilaColors.imageFadeScrimStrong],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(film.displayTitle)
                    .font(.filmilaDisplayMd)
                    .foregroundStyle(FilmilaColors.textPrimary)
                    .lineLimit(2)

                if let genre = film.genre, !genre.isEmpty {
                    Text(genre.uppercased())
                        .font(.filmilaLabel)
                        .foregroundStyle(FilmilaColors.accent)
                        .kerning(1.4)
                }

                HStack(spacing: Spacing.sm) {
                    if let durationText {
                        Text(durationText)
                            .font(.filmilaCaption)
                            .foregroundStyle(FilmilaColors.textSecondary)
                    }
                    Text(yearText)
                        .font(.filmilaCaption)
                        .foregroundStyle(FilmilaColors.textSecondary)
                }
            }
            .padding(Spacing.lg)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(16 / 9, contentMode: .fit)
        .clipped()
    }
}

#if DEBUG
#Preview {
    FilmHeroView(
        film: Film(
            id: 1,
            title: "Sample",
            description: "Desc",
            thumbnailUrl: "https://picsum.photos/seed/hero/1600/900",
            price: 0,
            status: .approved,
            genre: "Sci-Fi",
            duration: 7500,
            viewCount: 0,
            createdAt: Date()
        )
    )
    .preferredColorScheme(.dark)
}
#endif
