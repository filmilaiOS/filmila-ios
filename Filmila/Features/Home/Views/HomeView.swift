import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var auth: AuthService
    @StateObject private var vm: HomeViewModel
    @Binding private var selectedBrowseTab: HomeBrowseTab
    var onWatchlistAuthRequired: () -> Void

    init(
        container: AppContainer,
        selectedBrowseTab: Binding<HomeBrowseTab> = .constant(.films),
        onWatchlistAuthRequired: @escaping () -> Void = {}
    ) {
        _vm = StateObject(wrappedValue: HomeViewModel(container: container))
        _selectedBrowseTab = selectedBrowseTab
        self.onWatchlistAuthRequired = onWatchlistAuthRequired
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                HomeTopTabsBar(selected: $selectedBrowseTab)

                browseTabContent

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
            }
        }
        .background(FilmilaColors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await vm.loadAll()
        }
    }

    @ViewBuilder
    private var browseTabContent: some View {
        switch selectedBrowseTab {
        case .films:
            filmsHomeContent
        case .collections:
            ComingSoonView(title: String(localized: "shell_browse_collections"))
        case .genres:
            genresBrowseContent
        case .moods:
            ComingSoonView(title: String(localized: "shell_browse_moods"))
        }
    }

    @ViewBuilder
    private var filmsHomeContent: some View {
        if vm.isLoading, vm.featured.isEmpty {
            LoadingShimmer(width: nil, height: UIScreen.main.bounds.height * 0.48, cornerRadius: 0)
                .frame(height: UIScreen.main.bounds.height * 0.48)
        } else if let featured = vm.featured.first {
            FeaturedHeroSection(
                film: featured,
                averageRating: vm.averageRatingByFilmId[featured.id],
                onWatchlistAuthRequired: onWatchlistAuthRequired
            )
        }

        if auth.session != nil {
            ContinueWatchingRow(
                items: vm.continueWatchingItems,
                averageRatingByFilmId: vm.averageRatingByFilmId
            )
        }

        RecentReleasesRow(
            films: vm.recentlyAdded,
            averageRatingByFilmId: vm.averageRatingByFilmId
        )
    }

    @ViewBuilder
    private var genresBrowseContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(String(localized: "shell_browse_genres"))
                .font(.filmilaTitleSm)
                .foregroundStyle(FilmilaColors.textPrimary)
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)

            let genres = Array(
                Set(vm.recentlyAdded.compactMap { $0.genre?.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
            ).sorted()

            if genres.isEmpty, !vm.isLoading {
                Text(String(localized: "shell_coming_soon_body"))
                    .font(.filmilaBody)
                    .foregroundStyle(FilmilaColors.textSecondary)
                    .padding(.horizontal, Spacing.lg)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(genres, id: \.self) { genre in
                            Text(genre)
                                .font(.filmilaCaptionMd)
                                .foregroundStyle(FilmilaColors.textSecondary)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                                .background(FilmilaColors.surfaceElevated)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                }
            }

            RecentReleasesRow(
                films: vm.recentlyAdded,
                averageRatingByFilmId: vm.averageRatingByFilmId
            )
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        HomeView(container: PreviewContainer(), selectedBrowseTab: .constant(.films))
    }
    .environment(\.container, PreviewContainer())
    .environmentObject(PreviewContainer.makeSignedInAuthForPreviews())
    .preferredColorScheme(.dark)
}
#endif
