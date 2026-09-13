import SwiftUI

struct FeaturedHeroSection: View {
    let film: Film
    var averageRating: Double?
    var onWatchlistAuthRequired: () -> Void

    @Environment(\.container) private var container
    @EnvironmentObject private var auth: AuthService

    @State private var isInWatchlist = false
    @State private var isTogglingWatchlist = false

    private var isCompactHero: Bool {
        UIScreen.main.bounds.height < 720
    }

    private var heroHeight: CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        let proposed = screenHeight * 0.52
        if isCompactHero {
            return min(proposed, 340)
        }
        return min(proposed, 480)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                CachedAsyncImage(url: film.thumbnailUrl)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: Color.black.opacity(0.15), location: 0.45),
                        .init(color: FilmilaColors.background.opacity(0.92), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(film.displayTitle)
                        .font(.filmilaDisplayMd)
                        .foregroundStyle(FilmilaColors.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                        .multilineTextAlignment(.leading)

                    metadataRow

                    if let description = film.displayDescription?.trimmingCharacters(in: .whitespacesAndNewlines),
                       !description.isEmpty {
                        Text(description)
                            .font(.filmilaBody)
                            .foregroundStyle(FilmilaColors.textSecondary)
                            .lineLimit(isCompactHero ? 1 : 2)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 2)
                    }

                    HStack(spacing: Spacing.sm) {
                        NavigationLink {
                            FilmDetailView(filmId: film.id, container: container)
                        } label: {
                            Label(String(localized: "home_watch_now"), systemImage: "play.fill")
                                .font(.filmilaBodyMedium)
                        }
                        .buttonStyle(FilmilaAccentButtonStyle())

                        Button {
                            Task { await toggleWatchlist() }
                        } label: {
                            Label(
                                watchlistButtonTitle,
                                systemImage: isInWatchlist ? "checkmark" : "plus"
                            )
                            .font(.filmilaBodyMedium)
                        }
                        .buttonStyle(FilmilaAccentOutlineButtonStyle())
                        .disabled(isTogglingWatchlist)
                    }
                    .padding(.top, isCompactHero ? 4 : Spacing.sm)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, isCompactHero ? Spacing.md : Spacing.lg)
            }
            .frame(height: heroHeight)
            .frame(maxWidth: .infinity)
            .clipped()
        }
        .task(id: auth.session?.user.id) {
            await refreshWatchlistState()
        }
    }

    private var metadataRow: some View {
        ViewThatFits(in: .horizontal) {
            metadataContent(includeGenre: true)
            metadataContent(includeGenre: false)
        }
    }

    private func metadataContent(includeGenre: Bool) -> some View {
        HStack(spacing: Spacing.sm) {
            if let averageRating, averageRating > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(FilmilaColors.accent)
                    Text(Film.formattedAverageRating(averageRating))
                        .font(.filmilaCaptionMd)
                        .foregroundStyle(FilmilaColors.textPrimary)
                }
            }

            if let duration = film.formattedDurationForListing {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 11, weight: .medium))
                    Text(duration)
                        .font(.filmilaCaptionMd)
                }
                .foregroundStyle(FilmilaColors.textSecondary)
            }

            if includeGenre, let genre = film.localizedGenreLabel {
                Text(genre)
                    .font(.filmilaCapsBadge)
                    .foregroundStyle(FilmilaColors.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(FilmilaColors.surfaceElevated.opacity(0.85))
                    .clipShape(Capsule())
                    .lineLimit(1)
            }
        }
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
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
            // User can retry from detail screen.
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        FeaturedHeroSection(
            film: Film(
                id: 1,
                title: "Nour of Riyadh",
                description: "On a glittering evening in Boulevard Riyadh, a young calligrapher stumbles...",
                thumbnailUrl: "https://picsum.photos/800/1200",
                price: 18,
                status: .approved,
                genre: "Drama",
                duration: 1080,
                viewCount: 120,
                createdAt: Date()
            ),
            averageRating: 4.9,
            onWatchlistAuthRequired: {}
        )
    }
    .environment(\.container, PreviewContainer())
    .environmentObject(PreviewContainer.makeSignedInAuthForPreviews())
    .background(FilmilaColors.background)
    .preferredColorScheme(.dark)
}
#endif
