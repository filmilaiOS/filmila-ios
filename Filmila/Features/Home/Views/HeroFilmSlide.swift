import SwiftUI

struct HeroFilmSlide: View {
    let film: Film
    var averageRating: Double?
    @Environment(\.container) private var container

    private var genreUpper: String {
        (film.genre ?? "").trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    private var metaLine: String {
        let parts = [
            film.formattedDurationForListing,
            film.genre?.trimmingCharacters(in: .whitespacesAndNewlines),
            averageRating.map { Film.formattedAverageRating($0) }
        ].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        NavigationLink {
            FilmDetailView(filmId: film.id, container: container)
        } label: {
            ZStack(alignment: .bottom) {
                CachedAsyncImage(url: film.thumbnailUrl)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()

                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .clear, location: 0.35),
                        .init(color: FilmilaColors.background.opacity(0.92), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 0) {
                    Spacer(minLength: 0)

                    HStack(alignment: .bottom, spacing: Spacing.md) {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            if !genreLabelLine.isEmpty {
                                Text(genreLabelLine)
                                    .font(.filmilaLabel)
                                    .foregroundStyle(FilmilaColors.textSecondary)
                                    .tracking(2.4)
                                    .lineLimit(1)
                            }

                            Text(film.displayTitle)
                                .font(.filmilaDisplay)
                                .foregroundStyle(FilmilaColors.textPrimary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)

                            if !metaLine.isEmpty {
                                Text(metaLine)
                                    .font(.filmilaCaption)
                                    .foregroundStyle(FilmilaColors.textSecondary)
                                    .lineLimit(2)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        watchPill
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.lg)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Small caps style line with a middle dot (e.g. `FEATURED · DRAMA`).
    private var genreLabelLine: String {
        let prefix = String(localized: "home_hero_label_prefix")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        if genreUpper.isEmpty { return prefix }
        if prefix.isEmpty { return genreUpper }
        return "\(prefix) · \(genreUpper)"
    }

    private var watchPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "play.fill")
                .font(.system(size: 11, weight: .semibold))
            Text(String(localized: "home_watch"))
                .font(.filmilaBodyMedium)
        }
        .foregroundStyle(FilmilaColors.heroWatchButtonForeground)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(FilmilaColors.heroWatchButtonFill)
        )
        .accessibilityLabel(Text(String(localized: "home_watch")))
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        HeroFilmSlide(
            film: Film(
                id: 1,
                title: "Night Train",
                description: "A journey through the desert night.",
                thumbnailUrl: "https://picsum.photos/800/1200",
                price: 0,
                status: .approved,
                genre: "Thriller",
                duration: 5400,
                viewCount: 120,
                createdAt: Date()
            ),
            averageRating: 4.2
        )
    }
    .environment(\.container, PreviewContainer())
    .preferredColorScheme(.dark)
}
#endif
