import SwiftUI

struct WatchlistGridCard: View {
    let film: Film
    var averageRating: Double?
    var width: CGFloat
    var onRemove: (() -> Void)?

    private var posterHeight: CGFloat { width * 4 / 3 }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ZStack {
                CachedAsyncImage(url: film.thumbnailUrl)
                    .frame(width: width, height: posterHeight)
                    .clipped()

                VStack {
                    HStack {
                        FilmPricePill(film: film, compact: true)
                        Spacer(minLength: 0)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(FilmilaColors.accent)
                        .clipShape(Circle())
                        .shadow(color: FilmilaColors.accent.opacity(0.45), radius: 8, y: 4)
                    Spacer(minLength: 0)
                }
                .padding(10)
            }
            .frame(width: width, height: posterHeight)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(film.displayTitle)
                .font(.filmilaBodyMedium)
                .foregroundStyle(FilmilaColors.textPrimary)
                .lineLimit(1)

            HStack(spacing: 6) {
                if let filmmaker = publicFilmmakerName {
                    Text(filmmaker)
                        .font(.filmilaCaption)
                        .foregroundStyle(FilmilaColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                if let averageRating {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(FilmilaColors.accent)
                        Text(Film.formattedAverageRating(averageRating))
                            .font(.filmilaCaption)
                            .foregroundStyle(FilmilaColors.textSecondary)
                    }
                }

                if let duration = film.formattedDurationForListing {
                    Text("•")
                        .foregroundStyle(FilmilaColors.textMuted)
                    Text(duration)
                        .font(.filmilaCaption)
                        .foregroundStyle(FilmilaColors.textSecondary)
                }

                if let onRemove {
                    Button(action: onRemove) {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(FilmilaColors.textMuted)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(width: width, alignment: .topLeading)
    }

    /// Catalog `filmmaker` is often an email. Show a name only; omit the line otherwise.
    private var publicFilmmakerName: String? {
        guard let raw = film.filmmaker?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        if raw.contains("@") {
            return nil
        }
        return raw
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
