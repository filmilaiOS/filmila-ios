import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        Group {
            switch viewModel.phase {
            case .idle, .loading:
                ProgressView()
                    .tint(FilmilaColors.foregroundPrimary)
            case .empty:
                Text("home_empty")
                    .font(FilmilaTypography.bodyPrimary())
                    .foregroundStyle(FilmilaColors.foregroundSecondary)
                    .multilineTextAlignment(.center)
                    .padding()
            case let .failed(message):
                VStack(spacing: 12) {
                    Text(message)
                        .font(FilmilaTypography.bodyPrimary())
                        .foregroundStyle(FilmilaColors.danger)
                        .multilineTextAlignment(.center)
                    Button("home_retry") {
                        Task { await viewModel.load() }
                    }
                    .font(FilmilaTypography.bodyPrimary())
                }
                .padding()
            case let .content(films):
                List(films) { film in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(film.title)
                            .font(FilmilaTypography.sectionTitle())
                            .foregroundStyle(FilmilaColors.foregroundPrimary)
                        if let synopsis = film.synopsis, !synopsis.isEmpty {
                            Text(synopsis)
                                .font(FilmilaTypography.caption())
                                .foregroundStyle(FilmilaColors.foregroundSecondary)
                                .lineLimit(3)
                        }
                        Text(priceLabel(for: film))
                            .font(FilmilaTypography.caption())
                            .foregroundStyle(FilmilaColors.foregroundSecondary)
                    }
                    .listRowBackground(FilmilaColors.surface)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FilmilaColors.background.ignoresSafeArea())
        .navigationTitle(Text("home_title"))
        .task {
            await viewModel.load()
        }
    }

    private func priceLabel(for film: Film) -> String {
        if FilmAccessEvaluator.isFree(price: film.price) {
            return String(localized: "price_free")
        }
        return String(localized: "price_paid")
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        HomeView(viewModel: HomeViewModel(filmCatalog: PreviewFilmCatalogService()))
    }
    .preferredColorScheme(.dark)
}
#endif
