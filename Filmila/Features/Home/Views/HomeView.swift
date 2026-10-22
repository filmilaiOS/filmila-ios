import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var auth: AuthService
    @Environment(\.scenePhase) private var scenePhase
    @State private var featuredIndex = 0
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
            VStack(alignment: .leading, spacing: 0) {
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
            .padding(.bottom, Spacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FilmilaColors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await vm.loadAll()
        }
        .task(id: scenePhase == .active && selectedBrowseTab == .films && vm.featured.count > 1) {
            guard scenePhase == .active, selectedBrowseTab == .films, vm.featured.count > 1 else { return }
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(6)) }
                catch { break }
                guard !Task.isCancelled else { break }
                withAnimation(.easeInOut(duration: 0.45)) {
                    featuredIndex = (featuredIndex + 1) % vm.featured.count
                }
            }
        }
        .onChange(of: vm.featured.map(\.id)) { _ in
            featuredIndex = 0
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
        } else if !vm.featured.isEmpty {
            VStack(spacing: Spacing.sm) {
                TabView(selection: $featuredIndex) {
                    ForEach(Array(vm.featured.enumerated()), id: \.element.id) { index, film in
                        FeaturedHeroSection(
                            film: film,
                            averageRating: vm.averageRatingByFilmId[film.id],
                            onWatchlistAuthRequired: onWatchlistAuthRequired
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: min(UIScreen.main.bounds.height * 0.52, UIScreen.main.bounds.height < 720 ? 340 : 480))

                if vm.featured.count > 1 {
                    HStack(spacing: 7) {
                        ForEach(vm.featured.indices, id: \.self) { index in
                            Circle()
                                .fill(index == featuredIndex ? FilmilaColors.textPrimary : FilmilaColors.textPrimary.opacity(0.3))
                                .frame(width: index == featuredIndex ? 7 : 6, height: index == featuredIndex ? 7 : 6)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Film \(featuredIndex + 1) of \(vm.featured.count)")
                }
            }
        }

        if auth.session != nil {
            ContinueWatchingRow(
                items: vm.continueWatchingItems,
                averageRatingByFilmId: vm.averageRatingByFilmId
            )
        }

        FilmRowSection(
            title: String(localized: "home_trending"),
            films: vm.trending,
            averageRatingByFilmId: vm.averageRatingByFilmId,
            systemImage: "sparkles"
        )

        RecentReleasesRow(
            films: vm.recentlyAdded,
            averageRatingByFilmId: vm.averageRatingByFilmId
        )

        FilmRowSection(
            title: String(localized: "home_popular"),
            films: vm.featured,
            averageRatingByFilmId: vm.averageRatingByFilmId
        )
    }

    @ViewBuilder
    private var genresBrowseContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            FilmilaSectionHeader(title: String(localized: "shell_browse_genres"))

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
                            Text(Film.localizedGenreName(genre))
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
