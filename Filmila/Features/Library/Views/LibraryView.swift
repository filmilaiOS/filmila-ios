import SwiftUI
import UIKit

struct LibraryView: View {
    @StateObject private var vm: LibraryViewModel
    @Environment(\.container) private var container
    @Environment(\.mainTabSelection) private var mainTabSelection

    init(container: AppContainer) {
        _vm = StateObject(wrappedValue: LibraryViewModel(container: container))
    }

    private var posterColumnWidth: CGFloat {
        let screen = UIScreen.main.bounds.width
        let pad = Spacing.lg
        let mid = Spacing.md
        return max(150, (screen - pad - mid) / 2)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                librarySegmentedControl

                tabContent
            }
            .padding(.bottom, Spacing.xxl)
        }
        .background(FilmilaColors.background.ignoresSafeArea())
        .navigationTitle(String(localized: "library_title"))
        .navigationBarTitleDisplayMode(.large)
        .task {
            await vm.load()
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
                .stroke(FilmilaColors.surfaceBright.opacity(0.55), lineWidth: 1)
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
            .foregroundStyle(isSelected ? FilmilaColors.background : FilmilaColors.textSecondary)
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
            libraryGrid(films: vm.watchlist, emptyState: .watchlist)
        case .favorites:
            libraryGrid(films: vm.favorites, emptyState: .favorites)
        case .purchases:
            libraryGrid(films: vm.purchasedFilms, emptyState: .purchases)
        }
    }

    private enum LibraryEmptyKind {
        case watchlist
        case favorites
        case purchases
    }

    @ViewBuilder
    private func libraryGrid(films: [Film], emptyState: LibraryEmptyKind) -> some View {
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
                    spacing: Spacing.md
                ) {
                    ForEach(films) { film in
                        NavigationLink {
                            FilmDetailView(filmId: film.id, container: container)
                        } label: {
                            FilmPosterCard(
                                film: film,
                                width: posterColumnWidth,
                                averageRating: film.averageRating
                            )
                            .shadow(
                                color: .black.opacity(0.28),
                                radius: 10,
                                x: 0,
                                y: 6
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
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
    .environment(\.mainTabSelection, .constant(2))
    .preferredColorScheme(.dark)
}
#endif
