import SwiftUI

struct HomeView: View {
    @StateObject private var vm: HomeViewModel

    init(container: AppContainer) {
        _vm = StateObject(wrappedValue: HomeViewModel(container: container))
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                HeroCarouselView(films: vm.featured, isLoading: vm.isLoading)

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
                    .padding(Spacing.lg)
                }

                ContinueWatchingRow(items: vm.continueWatchingItems)

                FilmRowSection(title: String(localized: "home_trending"), films: vm.trending)
                FilmRowSection(title: String(localized: "home_new_arrivals"), films: vm.recentlyAdded)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(FilmilaColors.background.ignoresSafeArea())
        .navigationTitle(String(localized: "home_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task {
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
    .preferredColorScheme(.dark)
}
#endif
