import SwiftUI
import UIKit

struct LibraryView: View {
    @StateObject private var vm: LibraryViewModel
    @StateObject private var homeVM: HomeViewModel
    @EnvironmentObject private var auth: AuthService
    @Environment(\.container) private var container
    @Environment(\.mainTabSelection) private var mainTabSelection

    var onCreateAccount: () -> Void = {}
    var onLogIn: () -> Void = {}

    init(
        container: AppContainer,
        onCreateAccount: @escaping () -> Void = {},
        onLogIn: @escaping () -> Void = {}
    ) {
        _vm = StateObject(wrappedValue: LibraryViewModel(container: container))
        _homeVM = StateObject(wrappedValue: HomeViewModel(container: container))
        self.onCreateAccount = onCreateAccount
        self.onLogIn = onLogIn
    }

    private var posterColumnWidth: CGFloat {
        let screen = UIScreen.main.bounds.width
        let pad = Spacing.lg * 2
        let mid = Spacing.md
        return max(150, (screen - pad - mid) / 2)
    }

    var body: some View {
        ScrollView {
            Group {
                if auth.session == nil {
                    MyListLoggedOutView(
                        recommendedFilms: homeVM.recentlyAdded,
                        averageRatingByFilmId: homeVM.averageRatingByFilmId,
                        onCreateAccount: onCreateAccount,
                        onLogIn: onLogIn
                    )
                } else {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        watchlistHeader
                        librarySegmentedControl
                        tabContent
                    }
                }
            }
            .padding(.bottom, Spacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FilmilaColors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task(id: auth.session?.user.id) {
            if auth.session == nil {
                await homeVM.loadAll()
            } else {
                await vm.load()
            }
        }
    }

    private var watchlistHeader: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(FilmilaColors.accent)
                    Text(headerTitle)
                        .font(.filmilaDisplayMd)
                        .foregroundStyle(FilmilaColors.textPrimary)
                }

                Text(headerSubtitle)
                    .font(.filmilaCaption)
                    .foregroundStyle(FilmilaColors.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
    }

    private var headerTitle: String {
        switch vm.selectedTab {
        case .watchlist:
            String(localized: "library_watchlist_title")
        case .favorites:
            String(localized: "library_favorites_title")
        case .purchases:
            String(localized: "library_purchases_title")
        }
    }

    private var headerSubtitle: String {
        switch vm.selectedTab {
        case .watchlist:
            String(localized: "library_watchlist_subtitle")
        case .favorites:
            String(localized: "library_favorites_subtitle")
        case .purchases:
            String(localized: "library_purchases_subtitle")
        }
    }

    private var librarySegmentedControl: some View {
        HStack(spacing: 6) {
            ForEach(LibraryTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(5)
        .background(FilmilaColors.surfaceElevated)
        .clipShape(Capsule())
        .overlay(
            Capsule(style: .continuous)
                .stroke(FilmilaColors.cardBorder, lineWidth: 1)
        )
        .padding(.horizontal, Spacing.lg)
    }

    private func tabButton(_ tab: LibraryTab) -> some View {
        let isSelected = vm.selectedTab == tab
        let count = itemCount(for: tab)

        return Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                vm.selectedTab = tab
            }
        } label: {
            HStack(spacing: 6) {
                Text(tabTitle(tab))
                    .font(.filmilaCaptionMd)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text("\(count)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? FilmilaColors.accent : FilmilaColors.textMuted)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        Capsule(style: .continuous)
                            .fill(isSelected ? FilmilaColors.accentSubtle : FilmilaColors.surfaceBright)
                    )
            }
            .foregroundStyle(isSelected ? FilmilaColors.textInverse : FilmilaColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .background(
                Group {
                    if isSelected {
                        Capsule(style: .continuous)
                            .fill(FilmilaColors.accent)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }

    private func itemCount(for tab: LibraryTab) -> Int {
        switch tab {
        case .watchlist:
            vm.watchlist.count
        case .favorites:
            vm.favorites.count
        case .purchases:
            vm.purchasedFilms.count
        }
    }

    private func tabTitle(_ tab: LibraryTab) -> String {
        switch tab {
        case .watchlist:
            String(localized: "library_tab_watchlist")
        case .favorites:
            String(localized: "library_tab_favorites")
        case .purchases:
            String(localized: "library_tab_purchases")
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch vm.selectedTab {
        case .watchlist:
            libraryGrid(films: vm.watchlist, emptyState: .watchlist, allowsRemove: true)
        case .favorites:
            libraryGrid(films: vm.favorites, emptyState: .favorites, allowsRemove: false)
        case .purchases:
            libraryGrid(films: vm.purchasedFilms, emptyState: .purchases, allowsRemove: false)
        }
    }

    private enum LibraryEmptyKind {
        case watchlist
        case favorites
        case purchases
    }

    @ViewBuilder
    private func libraryGrid(films: [Film], emptyState: LibraryEmptyKind, allowsRemove: Bool) -> some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .tint(FilmilaColors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.top, Spacing.xxl)
            } else if films.isEmpty {
                emptyStateView(for: emptyState)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.fixed(posterColumnWidth), spacing: Spacing.md),
                        GridItem(.fixed(posterColumnWidth), spacing: Spacing.md)
                    ],
                    spacing: Spacing.lg
                ) {
                    ForEach(films) { film in
                        NavigationLink {
                            FilmDetailView(filmId: film.id, container: container)
                        } label: {
                            WatchlistGridCard(
                                film: film,
                                averageRating: film.averageRating,
                                width: posterColumnWidth,
                                onRemove: allowsRemove ? { removeFromWatchlist(film) } : nil
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
        }
    }

    private func removeFromWatchlist(_ film: Film) {
        Task {
            try? await container.filmsRepo.toggleWatchlist(filmId: film.id, add: false)
            await vm.load()
        }
    }

    @ViewBuilder
    private func emptyStateView(for kind: LibraryEmptyKind) -> some View {
        switch kind {
        case .watchlist:
            LibraryEmptyState(
                icon: "bookmark",
                title: String(localized: "library_empty_watchlist_title"),
                subtitle: String(localized: "library_empty_watchlist_subtitle"),
                actionTitle: String(localized: "library_browse_films"),
                action: browseFilms
            )
        case .favorites:
            LibraryEmptyState(
                icon: "heart",
                title: String(localized: "library_empty_favorites_title"),
                subtitle: String(localized: "library_empty_favorites_subtitle"),
                actionTitle: String(localized: "library_browse_films"),
                action: browseFilms
            )
        case .purchases:
            LibraryEmptyState(
                icon: "bag",
                title: String(localized: "library_empty_purchases_title"),
                subtitle: String(localized: "library_empty_purchases_subtitle"),
                actionTitle: String(localized: "library_browse_films"),
                action: browseFilms
            )
        }
    }

    private func browseFilms() {
        mainTabSelection?.wrappedValue = 0
    }
}

private struct LibraryEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill(FilmilaColors.accentSubtle)
                    .frame(width: 88, height: 88)
                Image(systemName: icon)
                    .font(.filmilaIconEmptyState)
                    .foregroundStyle(FilmilaColors.accent)
            }

            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.filmilaTitleSm)
                    .foregroundStyle(FilmilaColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.filmilaBody)
                    .foregroundStyle(FilmilaColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(FilmilaPrimaryButtonStyle())
                    .padding(.top, Spacing.sm)
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.xxl * 2)
        .frame(maxWidth: .infinity)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        LibraryView(container: PreviewContainer())
    }
    .environment(\.container, PreviewContainer())
    .environmentObject(PreviewContainer.makeSignedInAuthForPreviews())
    .environment(\.mainTabSelection, .constant(2))
    .preferredColorScheme(.dark)
}
#endif
