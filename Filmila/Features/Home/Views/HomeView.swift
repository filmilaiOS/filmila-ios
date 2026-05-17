import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var auth: AuthService
    @StateObject private var vm: HomeViewModel

    init(container: AppContainer) {
        _vm = StateObject(wrappedValue: HomeViewModel(container: container))
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                HeroCarouselView(
                    films: vm.featured,
                    isLoading: vm.isLoading,
                    averageRatingByFilmId: vm.averageRatingByFilmId
                )

                if let error = vm.error {
                    VStack(spacing: Spacing.sm) {
                        Text(error)
                            .font(.filmilaBody)
                            .foregroundStyle(FilmilaColors.destructive)
                            .multilineTextAlignment(.center)
                        Button(String(localized: "home_retry")) {
                            Task { await vm.loadAll() }
                        }
                        .font(.filmilaBodyMedium)
                        .foregroundStyle(FilmilaColors.accent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Spacing.lg)
                }

                ContinueWatchingRow(
                    items: vm.continueWatchingItems,
                    averageRatingByFilmId: vm.averageRatingByFilmId
                )

                FilmRowSection(
                    title: String(localized: "home_recommended"),
                    films: vm.recentlyAdded,
                    averageRatingByFilmId: vm.averageRatingByFilmId
                )
                FilmRowSection(
                    title: String(localized: "home_trending"),
                    films: vm.trending,
                    averageRatingByFilmId: vm.averageRatingByFilmId
                )
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(FilmilaColors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task(id: auth.session?.user.id) {
            guard auth.session != nil else { return }
            await vm.loadAll()
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        HomeView(container: PreviewContainer())
    }
    .environment(\.container, PreviewContainer())
    .environmentObject(PreviewContainer.makeSignedInAuthForPreviews())
    .preferredColorScheme(.dark)
}
#endif
