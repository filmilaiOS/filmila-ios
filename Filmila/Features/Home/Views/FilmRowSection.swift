import SwiftUI

struct FilmRowSection: View {
    let title: String
    let films: [Film]
    @Environment(\.container) private var container

    var body: some View {
        if !films.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(title)
                    .font(.filmilaTitleSm)
                    .foregroundStyle(FilmilaColors.textPrimary)
                    .padding(.horizontal, Spacing.lg)

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: Spacing.md) {
                        ForEach(films) { film in
                            NavigationLink {
                                FilmDetailView(filmId: film.id, container: container)
                            } label: {
                                FilmPosterCard(film: film)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                }
            }
            .padding(.top, Spacing.lg)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        FilmRowSection(
            title: "Trending",
            films: [
                Film(id: 1, title: "A", price: 0, status: .approved, viewCount: 0, createdAt: Date()),
                Film(id: 2, title: "B", price: 12, status: .approved, viewCount: 0, createdAt: Date())
            ]
        )
    }
    .environment(\.container, PreviewContainer())
    .background(FilmilaColors.background)
    .preferredColorScheme(.dark)
}
#endif
