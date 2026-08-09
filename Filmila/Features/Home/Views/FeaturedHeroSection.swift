import SwiftUI

struct FeaturedHeroSection: View {
    let film: Film
    var averageRating: Double?
    var onWatchlistAuthRequired: () -> Void

    @Environment(\.container) private var container
    @EnvironmentObject private var auth: AuthService

    @State private var isInWatchlist = false
    @State private var isTogglingWatchlist = false

    private var genreTag: String {
        (film.genre ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var durationTag: String? {
        film.formattedDurationForListing
    }

    private var metaLine: String {
        [genreTag, durationTag].compactMap { value in
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return trimmed.isEmpty ? nil : trimmed
        }.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                CachedAsyncImage(url: film.thumbnailUrl)
                    .frame(height: UIScreen.main.bounds.height * 0.48)
                    .frame(maxWidth: .infinity)
                    .clipped()

                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .clear, location: 0.35),
                        .init(color: FilmilaColors.background.opacity(0.95), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(String(localized: "home_editors_pick_label"))
                        .font(.filmilaLabel)
                        .foregroundStyle(FilmilaColors.textSecondary)
                        .tracking(2.2)

                    Text(film.displayTitle)
                        .font(.filmilaDisplayMd)
                        .foregroundStyle(FilmilaColors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if !metaLine.isEmpty {
                        Text(metaLine.uppercased())
                            .font(.filmilaCaptionMd)
                            .foregroundStyle(FilmilaColors.textSecondary)
                            .lineLimit(1)
                    }

                    if let description = film.displayDescription?.trimmingCharacters(in: .whitespacesAndNewlines),
                       !description.isEmpty {
                        Text(description)
                            .font(.filmilaBody)
                            .foregroundStyle(FilmilaColors.textSecondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .padding(.top, Spacing.xs)
                    }

                    HStack(spacing: Spacing.sm) {
                        NavigationLink {
                            FilmDetailView(filmId: film.id, container: container)
                        } label: {
                            Text(String(localized: "home_watch"))
                                .font(.filmilaBodyMedium)
                        }
                        .buttonStyle(FilmilaWhiteButtonStyle())

                        Button {
                            Task { await toggleWatchlist() }
                        } label: {
                            Text(watchlistButtonTitle)
                                .font(.filmilaBodyMedium)
                        }
                        .buttonStyle(FilmilaWhiteOutlineButtonStyle())
                        .disabled(isTogglingWatchlist)
                    }
                    .padding(.top, Spacing.sm)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
            }
        }
        .task(id: auth.session?.user.id) {
            await refreshWatchlistState()
        }
    }

    private var watchlistButtonTitle: String {
        if isInWatchlist {
            return String(localized: "home_my_list_added")
        }
        return String(localized: "home_my_list_add")
    }

    private func refreshWatchlistState() async {
        guard auth.session != nil else {
            isInWatchlist = false
            return
        }
        isInWatchlist = (try? await container.filmsRepo.isFilmInWatchlist(filmId: film.id)) ?? false
    }

    private func toggleWatchlist() async {
        guard auth.session != nil else {
            onWatchlistAuthRequired()
            return
        }
        guard !isTogglingWatchlist else { return }
        isTogglingWatchlist = true
        defer { isTogglingWatchlist = false }
        do {
            try await container.filmsRepo.toggleWatchlist(filmId: film.id, add: !isInWatchlist)
            isInWatchlist.toggle()
        } catch {
            // Same silent failure pattern as detail — user can retry from detail screen.
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        FeaturedHeroSection(
            film: Film(
                id: 1,
                title: "Night Train",
                description: "A journey through the desert night.",
                thumbnailUrl: "https://picsum.photos/800/1200",
                price: 0,
                status: .approved,
                genre: "Thriller",
                duration: 5400,
                viewCount: 120,
                createdAt: Date()
            ),
            averageRating: 4.2,
            onWatchlistAuthRequired: {}
        )
    }
    .environment(\.container, PreviewContainer())
    .environmentObject(PreviewContainer.makeSignedInAuthForPreviews())
    .environment(\.shellNavigation, ShellNavigationActions())
    .background(FilmilaColors.background)
    .preferredColorScheme(.dark)
}
#endif
