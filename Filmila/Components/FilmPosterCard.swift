import SwiftUI

struct FilmPosterCard: View {
    let film: Film
    var width: CGFloat = 130
    var averageRating: Double?
    /// When set, draws a progress track at the bottom of the poster image (e.g. continue watching).
    var bottomProgress: CGFloat?

    private var posterHeight: CGFloat {
        width * 3 / 2
    }

    private var durationBadge: String? {
        film.formattedDurationForListing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ZStack(alignment: .top) {
                CachedAsyncImage(url: film.thumbnailUrl)
                    .frame(width: width, height: posterHeight)
                    .clipped()

                badges

                if let bottomProgress {
                    VStack {
                        Spacer(minLength: 0)
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(FilmilaColors.overlayScrim)
                                .frame(height: 3)
                            Rectangle()
                                .fill(FilmilaColors.accent)
                                .frame(width: max(0, width * bottomProgress), height: 3)
                        }
                    }
                }
            }
            .frame(width: width, height: posterHeight)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(film.displayTitle)
                    .font(.filmilaTitleSm)
                    .foregroundStyle(FilmilaColors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let genre = film.genre?.trimmingCharacters(in: .whitespacesAndNewlines), !genre.isEmpty {
                    Text(genre)
                        .font(.filmilaCaption)
                        .foregroundStyle(FilmilaColors.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: width, alignment: .topLeading)
    }

    private var badges: some View {
        VStack {
            HStack(alignment: .top) {
                if let durationBadge {
                    Text(durationBadge)
                        .font(.filmilaCapsBadge)
                        .foregroundStyle(FilmilaColors.textPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule(style: .continuous)
                                .fill(FilmilaColors.posterBadgeBackdrop)
                        )
                }
                Spacer(minLength: 0)
                if let averageRating {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9, weight: .semibold))
                        Text(Film.formattedAverageRating(averageRating))
                            .font(.filmilaCapsBadge)
                    }
                    .foregroundStyle(FilmilaColors.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule(style: .continuous)
                            .fill(FilmilaColors.posterBadgeBackdrop)
                    )
                }
            }
            Spacer(minLength: 0)
        }
        .padding(8)
    }
}

#if DEBUG
#Preview {
    FilmPosterCard(
        film: Film(
            id: 1,
            title: "Sample",
            description: "Desc",
            thumbnailUrl: "https://picsum.photos/320/480",
            price: 19.99,
            status: .approved,
            genre: "Drama",
            duration: 3720,
            viewCount: 0,
            createdAt: Date()
        ),
        width: 130,
        averageRating: 4.3
    )
    .padding()
    .background(FilmilaColors.background)
    .preferredColorScheme(.dark)
}
#endif
