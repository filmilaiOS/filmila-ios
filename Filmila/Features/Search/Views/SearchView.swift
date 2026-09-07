import SwiftUI
import UIKit

private enum SearchGenres {
    static let options: [(key: String, label: String)] = [
        ("", String(localized: "search_filter_all")),
        ("Drama", String(localized: "genre_drama")),
        ("Comedy", String(localized: "genre_comedy")),
        ("Documentary", String(localized: "genre_documentary")),
        ("Animation", String(localized: "genre_animation")),
        ("Horror", String(localized: "genre_horror")),
        ("Romance", String(localized: "genre_romance")),
        ("Thriller", String(localized: "genre_thriller"))
    ]
}

private struct PosterShimmerPlaceholder: View {
    let width: CGFloat
    @State private var phase: CGFloat = 0

    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(FilmilaColors.surfaceBright)
            .frame(width: width, height: 72)
            .overlay {
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            Color.clear,
                            FilmilaColors.searchPosterShimmerHighlight,
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.45)
                    .offset(x: phase * (geo.size.width + geo.size.width * 0.45))
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

struct SearchView: View {
    @StateObject private var vm: SearchViewModel
    @Environment(\.container) private var container
    @Binding private var externalSearchQuery: String?

    @AppStorage("filmila.recentSearches") private var recentSearchesStorage = ""
    @State private var popularFilms: [Film] = []
    @State private var comingSoonTitle: String?

    init(
        container: AppContainer,
        externalSearchQuery: Binding<String?> = .constant(nil)
    ) {
        _vm = StateObject(wrappedValue: SearchViewModel(container: container))
        _externalSearchQuery = externalSearchQuery
    }

    private var recentSearches: [String] {
        recentSearchesStorage
            .split(separator: "|")
            .map(String.init)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private var trimmedQuery: String {
        vm.query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                searchField
                genreChips

                if vm.isLoading {
                    loadingRows
                } else if vm.results.isEmpty, trimmedQuery.count >= 2 {
                    noResultsState
                } else if !vm.results.isEmpty {
                    resultsList
                } else {
                    browseContent
                }
            }
            .padding(.bottom, Spacing.xxl)
        }
        .background(FilmilaColors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            popularFilms = (try? await container.filmsRepo.fetchTrending()) ?? []
        }
        .onChange(of: vm.query) { _ in
            vm.onSearchControlsChanged()
        }
        .onChange(of: vm.selectedGenre) { _ in
            vm.onSearchControlsChanged()
        }
        .onChange(of: externalSearchQuery) { value in
            guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            vm.query = value
            externalSearchQuery = nil
            vm.onSearchControlsChanged()
        }
        .onChange(of: vm.isLoading) { loading in
            if !loading, !vm.results.isEmpty, trimmedQuery.count >= 2 {
                rememberSearch(trimmedQuery)
            }
        }
        .onDisappear {
            vm.cancelPendingSearch()
        }
        .alert(
            comingSoonTitle ?? "",
            isPresented: Binding(
                get: { comingSoonTitle != nil },
                set: { if !$0 { comingSoonTitle = nil } }
            )
        ) {
            Button(String(localized: "detail_iap_close"), role: .cancel) {
                comingSoonTitle = nil
            }
        } message: {
            Text(String(localized: "shell_coming_soon_body"))
        }
    }

    private var searchField: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(FilmilaColors.textMuted)
            TextField(String(localized: "search_field_placeholder_v2"), text: $vm.query)
                .textFieldStyle(.plain)
                .foregroundStyle(FilmilaColors.textPrimary)
                .font(.filmilaBody)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !vm.query.isEmpty {
                Button {
                    vm.query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(FilmilaColors.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 14)
        .background(FilmilaColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(FilmilaColors.cardBorder, lineWidth: 1)
        )
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
    }

    private var genreChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(SearchGenres.options, id: \.key) { item in
                    let isSelected = (vm.selectedGenre ?? "") == item.key
                    Button {
                        if isSelected, !item.key.isEmpty {
                            vm.selectedGenre = nil
                        } else if item.key.isEmpty {
                            vm.selectedGenre = nil
                        } else {
                            vm.selectedGenre = item.key
                        }
                    } label: {
                        Text(item.label)
                            .font(.filmilaCaptionMd)
                            .foregroundStyle(isSelected ? FilmilaColors.textInverse : FilmilaColors.textSecondary)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, 10)
                            .background(isSelected ? FilmilaColors.accent : FilmilaColors.surfaceElevated)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
    }

    @ViewBuilder
    private var browseContent: some View {
        if !recentSearches.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.md) {
                FilmilaSectionHeader(
                    title: String(localized: "search_recent_searches"),
                    trailingTitle: String(localized: "search_clear_all"),
                    trailingAction: clearRecentSearches
                )

                FlowLayout(spacing: Spacing.sm) {
                    ForEach(recentSearches, id: \.self) { term in
                        recentSearchChip(term)
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
        }

        if !popularFilms.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.md) {
                FilmilaSectionHeader(
                    title: String(localized: "search_popular_searches"),
                    systemImage: "sparkles",
                    accentTitle: false
                )

                VStack(spacing: Spacing.sm) {
                    ForEach(popularFilms.prefix(6)) { film in
                        NavigationLink {
                            FilmDetailView(filmId: film.id, container: container)
                        } label: {
                            SearchResultRowCard(film: film)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
        } else {
            Text(String(localized: "search_empty_browse_hint"))
                .font(.filmilaBody)
                .foregroundStyle(FilmilaColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.xl)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)
        }
    }

    private func recentSearchChip(_ term: String) -> some View {
        HStack(spacing: 6) {
            Button {
                vm.query = term
                vm.onSearchControlsChanged()
            } label: {
                Text(term)
                    .font(.filmilaCaptionMd)
                    .foregroundStyle(FilmilaColors.textPrimary)
            }
            .buttonStyle(.plain)

            Button {
                removeRecentSearch(term)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(FilmilaColors.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(FilmilaColors.surfaceElevated)
        .clipShape(Capsule())
    }

    private var loadingRows: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(0 ..< 4, id: \.self) { _ in
                PosterShimmerPlaceholder(width: UIScreen.main.bounds.width - Spacing.lg * 2)
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    private var resultsList: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(vm.results) { film in
                NavigationLink {
                    FilmDetailView(filmId: film.id, container: container)
                } label: {
                    SearchResultRowCard(film: film)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    private var noResultsState: some View {
        Text(String(localized: "search_empty"))
            .font(.filmilaBody)
            .foregroundStyle(FilmilaColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.top, Spacing.xxl)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Spacing.lg)
    }

    private func rememberSearch(_ term: String) {
        var items = recentSearches.filter { $0.caseInsensitiveCompare(term) != .orderedSame }
        items.insert(term, at: 0)
        recentSearchesStorage = items.prefix(8).joined(separator: "|")
    }

    private func removeRecentSearch(_ term: String) {
        let items = recentSearches.filter { $0 != term }
        recentSearchesStorage = items.joined(separator: "|")
    }

    private func clearRecentSearches() {
        recentSearchesStorage = ""
    }
}

/// Simple wrapping layout for recent-search chips.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SearchView(container: PreviewContainer(), externalSearchQuery: .constant(nil))
    }
    .environment(\.container, PreviewContainer())
    .preferredColorScheme(.dark)
}
#endif
