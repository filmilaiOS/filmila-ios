import SwiftUI

struct HeroFilmSlide: View {
    let film: Film
    @Environment(\.container) private var container

    var body: some View {
        NavigationLink {
            FilmDetailView(filmId: film.id, container: container)
        } label: {
            ZStack(alignment: .bottomLeading) {
                CachedAsyncImage(url: film.thumbnailUrl)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()

                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .clear, location: 0.4),
                        .init(color: FilmilaColors.background, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    if let genre = film.genre, !genre.isEmpty {
                        Text(genre.uppercased())
                            .font(.filmilaLabel)
                            .foregroundStyle(FilmilaColors.accent)
                            .kerning(1.6)
                    }
                    Text(film.displayTitle)
                        .font(.filmilaDisplay)
                        .foregroundStyle(FilmilaColors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    if let desc = film.displayDescription, !desc.isEmpty {
                        Text(desc)
                            .font(.filmilaCaption)
                            .foregroundStyle(FilmilaColors.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
            )
        )
    }
    .environment(\.container, PreviewContainer())
    .preferredColorScheme(.dark)
}
#endif
