import SwiftUI

struct RootView: View {
    @StateObject private var homeViewModel: HomeViewModel

    init(container: any AppContainer) {
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(filmCatalog: container.filmCatalog))
    }

    var body: some View {
        NavigationStack {
            HomeView(viewModel: homeViewModel)
        }
    }
}

#if DEBUG
private struct PreviewRootContainer: AppContainer {
    let filmCatalog: FilmCatalogServing

    init() {
        filmCatalog = PreviewFilmCatalogService()
    }
}

#Preview {
    RootView(container: PreviewRootContainer())
        .preferredColorScheme(.dark)
}
#endif
