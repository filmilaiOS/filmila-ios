import SwiftUI

struct FilmRowSection: View {
    let title: String
    let films: [Film]
    var averageRatingByFilmId: [Int: Double] = [:]
    @Environment(\.container) private var container

    var body: some View {
        if !films.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text(title)
                    .font(.filmilaLabel)
                    .foregroundStyle(FilmilaColors.textPrimary)
                    .tracking(2.2)
                    .padding(.horizontal, Spacing.lg)

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
        FilmRowSection(
            title: "Trending",
            films: [
                Film(id: 1, title: "A", price: 0, status: .approved, genre: "Drama", duration: 3000, viewCount: 0, createdAt: Date()),
                Film(id: 2, title: "B", price: 12, status: .approved, genre: "Thriller", duration: 4200, viewCount: 0, createdAt: Date())
            ],
            averageRatingByFilmId: [1: 4.1, 2: 3.8]
        )
    }
    .environment(\.container, PreviewContainer())
    .background(FilmilaColors.background)
    .preferredColorScheme(.dark)
}
#endif
