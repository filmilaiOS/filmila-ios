import SwiftUI

struct ContinueWatchingRow: View {
    let items: [ContinueWatchingItem]
    var averageRatingByFilmId: [Int: Double] = [:]
    @Environment(\.container) private var container

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text(String(localized: "home_continue_watching"))
                    .font(.filmilaLabel)
                    .foregroundStyle(FilmilaColors.textPrimary)
                    .tracking(2.2)
                    .padding(.horizontal, Spacing.lg)

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: Spacing.md) {
                        ForEach(items) { item in
                            ContinueWatchingCard(
                                item: item,
                                averageRating: averageRatingByFilmId[item.film.id]
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                }
            }
            .padding(.top, Spacing.xl)
        }
    }
}

private struct ContinueWatchingCard: View {
    let item: ContinueWatchingItem
    var averageRating: Double?
    @Environment(\.container) private var container
    private let cardWidth: CGFloat = 130

    private var progress: CGFloat {
        guard let duration = item.film.duration, duration > 0 else { return 0 }
        return min(1, CGFloat(item.progress.progressSeconds) / CGFloat(duration))
    }

    var body: some View {
        NavigationLink {
            FilmDetailView(filmId: item.film.id, container: container)
        } label: {
            FilmPosterCard(
                film: item.film,
                width: cardWidth,
                averageRating: averageRating,
                bottomProgress: progress
            )
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ContinueWatchingRow(
            items: [
                ContinueWatchingItem(
                    film: Film(
                        id: 1,
                        title: "Continue",
                        thumbnailUrl: "https://picsum.photos/seed/cw/400/600",
                        price: 9,
                        status: .approved,
                        genre: "Sci-Fi",
                        duration: 3600,
                        viewCount: 0,
                        createdAt: Date()
                    ),
                    progress: FilmProgress(
                        userId: UUID(),
                        filmId: 1,
                        progressSeconds: 900
                    )
                )
            ],
            averageRatingByFilmId: [1: 4.0]
        )
    }
    .environment(\.container, PreviewContainer())
    .background(FilmilaColors.background)
    .preferredColorScheme(.dark)
}
#endif
