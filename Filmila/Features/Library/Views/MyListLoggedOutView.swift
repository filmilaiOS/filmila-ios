import SwiftUI

struct MyListLoggedOutView: View {
    let recommendedFilms: [Film]
    var averageRatingByFilmId: [Int: Double] = [:]
    var onCreateAccount: () -> Void
    var onLogIn: () -> Void

    @Environment(\.container) private var container

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            VStack(spacing: Spacing.lg) {
                Text(String(localized: "mylist_logged_out_title"))
                    .font(.filmilaDisplayMd)
                    .foregroundStyle(FilmilaColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(String(localized: "mylist_logged_out_subtitle"))
                    .font(.filmilaBody)
                    .foregroundStyle(FilmilaColors.textSecondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: Spacing.sm) {
                    Button(action: onCreateAccount) {
                        Text(String(localized: "auth_create_account"))
                            .font(.filmilaBodyMedium)
                    }
                    .buttonStyle(FilmilaWhiteButtonStyle())

                    Button(action: onLogIn) {
                        Text(String(localized: "auth_sign_in"))
                            .font(.filmilaBodyMedium)
                    }
                    .buttonStyle(FilmilaWhiteOutlineButtonStyle())
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.xl)

            if !recommendedFilms.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text(String(localized: "mylist_recommended_heading"))
                        .font(.filmilaLabel)
                        .foregroundStyle(FilmilaColors.textPrimary)
                        .tracking(2.2)
                        .padding(.horizontal, Spacing.lg)

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .top, spacing: Spacing.md) {
                            ForEach(recommendedFilms) { film in
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
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ScrollView {
            MyListLoggedOutView(
                recommendedFilms: [
                    Film(id: 1, title: "A", price: 0, status: .approved, genre: "Drama", duration: 3000, viewCount: 0, createdAt: Date())
                ],
                onCreateAccount: {},
                onLogIn: {}
            )
        }
    }
    .environment(\.container, PreviewContainer())
    .background(FilmilaColors.background)
    .preferredColorScheme(.dark)
}
#endif
