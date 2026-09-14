import SwiftUI

struct RecentReleasesRow: View {
    let films: [Film]
    var averageRatingByFilmId: [Int: Double] = [:]
    @Environment(\.container) private var container

    var body: some View {
        if !films.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.md) {
                FilmilaSectionHeader(
                    title: String(localized: "home_recent_releases"),
                    systemImage: "film.fill"
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: Spacing.md) {
                        ForEach(films) { film in
                            NavigationLink {
                                FilmDetailView(filmId: film.id, container: container)
                            } label: {
                                FilmPosterCard(
                                    film: film,
                                    width: 130,
                                    averageRating: averageRatingByFilmId[film.id]
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                }
            }
            .padding(.top, Spacing.xl)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        RecentReleasesRow(
            films: [
                Film(id: 1, title: "Night Train", price: 0, status: .approved, genre: "Drama", duration: 3000, viewCount: 0, createdAt: Date())
            ]
        )
    }
    .environment(\.container, PreviewContainer())
    .background(FilmilaColors.background)
    .preferredColorScheme(.dark)
}
#endif
