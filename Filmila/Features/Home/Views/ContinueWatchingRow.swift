import SwiftUI

struct ContinueWatchingRow: View {
    let items: [ContinueWatchingItem]
    @Environment(\.container) private var container

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(String(localized: "home_continue_watching"))
                    .font(.filmilaTitleSm)
                    .foregroundStyle(FilmilaColors.textPrimary)
                    .padding(.horizontal, Spacing.lg)

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: Spacing.md) {
                        ForEach(items) { item in
                            ContinueWatchingCard(item: item)
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                }
            }
            .padding(.top, Spacing.md)
        }
    }
}

private struct ContinueWatchingCard: View {
    let item: ContinueWatchingItem
    @Environment(\.container) private var container
    private let cardWidth: CGFloat = 140

    private var progress: CGFloat {
        guard let duration = item.film.duration, duration > 0 else { return 0 }
        return min(1, CGFloat(item.progress.progressSeconds) / CGFloat(duration))
    }

    var body: some View {
        NavigationLink {
            FilmDetailView(filmId: item.film.id, container: container)
        } label: {
            FilmPosterCard(film: item.film, width: cardWidth)
                .overlay(alignment: .bottom) {
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(FilmilaColors.overlayScrim)
                            .frame(height: 4)
                        Rectangle()
                            .fill(FilmilaColors.accent)
                            .frame(width: max(0, cardWidth * progress), height: 2)
                    }
                    .frame(width: cardWidth, height: 4)
                }
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
            ]
        )
    }
    .environment(\.container, PreviewContainer())
    .background(FilmilaColors.background)
    .preferredColorScheme(.dark)
}
#endif
