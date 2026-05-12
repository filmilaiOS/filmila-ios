import SwiftUI
import UIKit

private enum SearchGenres {
    static let options: [(key: String, label: String)] = [
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
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(FilmilaColors.surfaceBright)
            .frame(width: width, height: width * 1.5)
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
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
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

    init(container: AppContainer, externalSearchQuery: Binding<String?> = .constant(nil)) {
        _vm = StateObject(wrappedValue: SearchViewModel(container: container))
        _externalSearchQuery = externalSearchQuery
    }

    private var posterColumnWidth: CGFloat {
        let screen = UIScreen.main.bounds.width
        let pad = Spacing.lg * 2
        let mid = Spacing.md
        return max(120, (screen - pad - mid) / 2)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                searchField

                genreChips

                if vm.isLoading {
                    shimmerGrid
                } else if vm.results.isEmpty, vm.query.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 {
                    emptyState
                } else if vm.results.isEmpty {
                    Color.clear.frame(height: 1)
                } else {
                    resultsGrid
                }
            }
            .padding(.bottom, Spacing.xxl)
        }
        .background(FilmilaColors.background.ignoresSafeArea())
        .navigationTitle(String(localized: "search_title"))
        .navigationBarTitleDisplayMode(.large)
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
        .onDisappear {
            vm.cancelPendingSearch()
        }
    }

    private var searchField: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(FilmilaColors.textMuted)
            TextField(String(localized: "search_field_placeholder"), text: $vm.query)
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
        .padding(.vertical, Spacing.sm + 2)
        .background(FilmilaColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(FilmilaColors.surfaceBright.opacity(0.6), lineWidth: 1)
        )
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
    }

    private var genreChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(SearchGenres.options, id: \.key) { item in
                    let isSelected = vm.selectedGenre == item.key
                    Button {
                        if vm.selectedGenre == item.key {
                            vm.selectedGenre = nil
                        } else {
                            vm.selectedGenre = item.key
                        }
                    } label: {
                        Text(item.label)
                            .font(.filmilaCaptionMd)
                            .foregroundStyle(isSelected ? FilmilaColors.background : FilmilaColors.textSecondary)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(isSelected ? FilmilaColors.accent : FilmilaColors.surfaceElevated)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
    }

    private var shimmerGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.fixed(posterColumnWidth), spacing: Spacing.md),
                GridItem(.fixed(posterColumnWidth), spacing: Spacing.md)
            ],
            spacing: Spacing.md
        ) {
            ForEach(0 ..< 6, id: \.self) { _ in
                PosterShimmerPlaceholder(width: posterColumnWidth)
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    private var resultsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.fixed(posterColumnWidth), spacing: Spacing.md),
                GridItem(.fixed(posterColumnWidth), spacing: Spacing.md)
            ],
            spacing: Spacing.md
        ) {
            ForEach(vm.results) { film in
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

    private var emptyState: some View {
        Text(String(localized: "search_empty"))
            .font(.filmilaBody)
            .foregroundStyle(FilmilaColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.top, Spacing.xxl)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Spacing.lg)
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
