import SwiftUI
import UIKit

struct LibraryView: View {
    @StateObject private var vm: LibraryViewModel
    @Environment(\.container) private var container

    init(container: AppContainer) {
        _vm = StateObject(wrappedValue: LibraryViewModel(container: container))
    }

    private var posterColumnWidth: CGFloat {
        let screen = UIScreen.main.bounds.width
        let pad = Spacing.lg * 2
        let mid = Spacing.md
        return max(120, (screen - pad - mid) / 2)
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
        HStack(spacing: 0) {
            ForEach(LibraryTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        vm.selectedTab = tab
                    }
                } label: {
                    Text(tabTitle(tab))
                        .font(.filmilaCaptionMd)
                        .foregroundStyle(vm.selectedTab == tab ? FilmilaColors.background : FilmilaColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm + 2)
                        .background(
                            Group {
                                if vm.selectedTab == tab {
                                    FilmilaColors.accent
                                } else {
                                    Color.clear
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(FilmilaColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(FilmilaColors.surfaceBright.opacity(0.5), lineWidth: 1)
        )
        .padding(.horizontal, Spacing.lg)
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
            libraryGrid(films: vm.watchlist, emptyText: String(localized: "library_empty_watchlist"))
        case .favorites:
            libraryGrid(films: vm.favorites, emptyText: String(localized: "library_empty_favorites"))
        case .purchases:
            libraryGrid(films: vm.purchasedFilms, emptyText: String(localized: "library_empty_purchases"))
        }
    }

    private func libraryGrid(films: [Film], emptyText: String) -> some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .tint(FilmilaColors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.top, Spacing.xxl)
            } else if films.isEmpty {
                Text(emptyText)
                    .font(.filmilaBody)
                    .foregroundStyle(FilmilaColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, Spacing.xxl)
                    .padding(.horizontal, Spacing.lg)
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
                            FilmPosterCard(film: film, width: posterColumnWidth)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        LibraryView(container: PreviewContainer())
    }
    .environment(\.container, PreviewContainer())
    .preferredColorScheme(.dark)
}
#endif
