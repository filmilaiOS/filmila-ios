import SwiftUI

struct ContinueWatchingRow: View {
    let items: [ContinueWatchingItem]
    var averageRatingByFilmId: [Int: Double] = [:]
    @Environment(\.container) private var container

    private let cardWidth: CGFloat = 280

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.md) {
                FilmilaSectionHeader(
                    title: String(localized: "home_continue_watching"),
                    systemImage: "clock.fill",
                    accentTitle: true
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: Spacing.md) {
                        ForEach(items) { item in
                            ContinueWatchingCard(item: item)
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
    @Environment(\.container) private var container

    private let cardHeight: CGFloat = 160

    private var progress: CGFloat {
        guard let duration = item.film.duration, duration > 0 else { return 0 }
        return min(1, CGFloat(item.progress.progressSeconds) / CGFloat(duration))
    }

    var body: some View {
        NavigationLink {
            FilmDetailView(filmId: item.film.id, container: container)
        } label: {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ZStack {
                    CachedAsyncImage(url: item.film.thumbnailUrl)
                        .frame(width: cardHeight * 16 / 9, height: cardHeight)
                        .clipped()

                    Image(systemName: "play.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(FilmilaColors.accent)
                        .clipShape(Circle())

                    VStack {
                        Spacer(minLength: 0)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.2))
                                Rectangle()
                                    .fill(FilmilaColors.accent)
                                    .frame(width: geo.size.width * progress)
                            }
                        }
                        .frame(height: 3)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Text(item.film.displayTitle)
                    .font(.filmilaBodyMedium)
                    .foregroundStyle(FilmilaColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if let filmmaker = item.film.filmmaker?.trimmingCharacters(in: .whitespacesAndNewlines), !filmmaker.isEmpty {
                        Text(filmmaker)
                            .lineLimit(1)
                    }
                    if let duration = item.film.formattedDurationForListing {
                        Text("• \(duration)")
                    }
                }
                .font(.filmilaCaption)
                .foregroundStyle(FilmilaColors.textSecondary)
            }
            .frame(width: cardHeight * 16 / 9, alignment: .leading)
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
                        title: "Nour of Riyadh",
                        thumbnailUrl: "https://picsum.photos/seed/cw/640/360",
                        price: 18,
                        status: .approved,
                        genre: "Drama",
                        duration: 1080,
                        viewCount: 0,
                        filmmaker: "Nora Al-Dossary",
                        createdAt: Date()
                    ),
                    progress: FilmProgress(
                        userId: UUID(),
                        filmId: 1,
                        progressSeconds: 540
                    )
                )
            ]
        )
    }
    .environment(\.container, PreviewContainer())
    .background(FilmilaColors.background)
    .preferredColorScheme(.dark)
}
#endif
