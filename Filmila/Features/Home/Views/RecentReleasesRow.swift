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
                                FilmPosterCardWithGenreOverlay(
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

struct FilmPosterCardWithGenreOverlay: View {
    let film: Film
    var width: CGFloat = 130
    var averageRating: Double?

    var body: some View {
        ZStack(alignment: .topLeading) {
            FilmPosterCard(film: film, width: width, averageRating: averageRating)

            if let genre = film.genre?.trimmingCharacters(in: .whitespacesAndNewlines), !genre.isEmpty {
                Text(genre)
                    .font(.filmilaCapsBadge)
                    .foregroundStyle(FilmilaColors.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(FilmilaColors.posterBadgeBackdrop)
                    .clipShape(Capsule())
                    .padding(8)
            }
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
