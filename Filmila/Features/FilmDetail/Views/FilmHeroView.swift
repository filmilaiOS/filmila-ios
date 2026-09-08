import SwiftUI
import UIKit

struct FilmHeroView: View {
    let film: Film
    let container: AppContainer
    var averageRating: Double = 0
    var ratingCount: Int = 0
    var filmmaker: FilmmakerProfile?

    private let directorAvatarSize: CGFloat = 76

    private var yearText: String {
        String(Calendar.current.component(.year, from: film.createdAt))
    }

    private var durationText: String? {
        film.formattedDurationForListing
    }

    private var shareURL: URL {
        Env.apiBaseURL.appendingPathComponent("films/\(film.id)", isDirectory: false)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            heroBanner

            if let filmmaker {
                directorSection(filmmaker)
            }
        }
    }

    private var heroBanner: some View {
        ZStack(alignment: .bottomLeading) {
            CachedAsyncImage(url: film.thumbnailUrl)
                .aspectRatio(16 / 9, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipped()

            LinearGradient(
                colors: [.clear, FilmilaColors.imageFadeScrimStrong],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(film.displayTitle)
                    .font(.filmilaDisplayMd)
                    .foregroundStyle(FilmilaColors.textPrimary)
                    .lineLimit(2)

                if let genre = film.genre, !genre.isEmpty {
                    Text(genre.uppercased())
                        .font(.filmilaLabel)
                        .foregroundStyle(FilmilaColors.accent)
                        .kerning(1.4)
                }

                HStack(spacing: Spacing.sm) {
                    if let durationText {
                        Text(durationText)
                            .font(.filmilaCaption)
                            .foregroundStyle(FilmilaColors.textSecondary)
                    }
                    Text(yearText)
                        .font(.filmilaCaption)
                        .foregroundStyle(FilmilaColors.textSecondary)

                    if averageRating > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10, weight: .semibold))
                            Text(Film.formattedAverageRating(averageRating))
                                .font(.filmilaCaption)
                        }
                        .foregroundStyle(FilmilaColors.textPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule(style: .continuous)
                                .fill(FilmilaColors.posterBadgeBackdrop)
                        )
                        .accessibilityLabel(heroRatingAccessibilityLabel)
                    }
                }
            }
            .padding(Spacing.lg)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(16 / 9, contentMode: .fit)
        .clipped()
    }

    private func directorSection(_ profile: FilmmakerProfile) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "detail_director"))
                .font(.filmilaLabel)
                .foregroundStyle(FilmilaColors.textMuted)
                .kerning(1.2)
                .padding(.horizontal, Spacing.lg)

            HStack(alignment: .center, spacing: Spacing.md) {
                NavigationLink {
                    DirectorProfileView(directorId: profile.id, container: container)
                } label: {
                    HStack(spacing: Spacing.md) {
                        DirectorAvatarView(
                            urlString: profile.resolvedAvatarURL,
                            initials: filmmakerInitials(profile),
                            size: directorAvatarSize
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(filmmakerDisplayName(profile))
                                .font(.filmilaBodyMedium)
                                .foregroundStyle(FilmilaColors.textPrimary)
                                .lineLimit(2)

                            Text(String(localized: "detail_director_subtitle"))
                                .font(.filmilaCaption)
                                .foregroundStyle(FilmilaColors.textSecondary)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 0)

                        Text(String(localized: "detail_view_profile"))
                            .font(.filmilaCaptionMd)
                            .foregroundStyle(FilmilaColors.accent)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(DirectorRowButtonStyle())
                .accessibilityLabel(Text(filmmakerDisplayName(profile)))
                .accessibilityHint(Text(String(localized: "detail_director_profile_hint")))
            }
            .padding(Spacing.md)
            .background(FilmilaColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(FilmilaColors.cardBorder, lineWidth: 1)
            )
            .padding(.horizontal, Spacing.lg)

            HStack {
                Spacer()
                ShareLink(item: shareURL) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.filmilaIconDetail)
                        .foregroundStyle(FilmilaColors.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(FilmilaColors.surfaceElevated)
                        .clipShape(Circle())
                }
                .accessibilityLabel(Text(String(localized: "detail_share_film")))
            }
            .padding(.horizontal, Spacing.lg)
        }
    }

    private var heroRatingAccessibilityLabel: Text {
        if ratingCount > 0 {
            return Text(String(format: String(localized: "detail_rating_average_format"), averageRating, ratingCount))
        }
        return Text(Film.formattedAverageRating(averageRating))
    }

    private func filmmakerDisplayName(_ profile: FilmmakerProfile) -> String {
        let trimmed = profile.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmed.isEmpty { return trimmed }
        return String(localized: "detail_director_fallback")
    }

    private func filmmakerInitials(_ profile: FilmmakerProfile) -> String {
        let source = filmmakerDisplayName(profile)
        let parts = source.split(separator: " ").map(String.init)
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(source.prefix(2)).uppercased()
    }
}

// MARK: - Director row press feedback

private struct DirectorRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.72 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Director avatar (explicit sizing; initials only when URL is absent)

private struct DirectorAvatarView: View {
    let urlString: String?
    let initials: String
    let size: CGFloat

    @State private var loadedImage: UIImage?
    @State private var didFail = false

    private var normalizedURLString: String? {
        guard let raw = urlString?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        return raw
    }

    private var remoteURL: URL? {
        guard let normalizedURLString,
              let url = URL(string: normalizedURLString),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else { return nil }
        return url
    }

    private var shouldShowInitials: Bool {
        normalizedURLString == nil || remoteURL == nil
    }

    var body: some View {
        ZStack {
            if shouldShowInitials {
                initialsCircle
            } else if let loadedImage {
                Image(uiImage: loadedImage)
                    .resizable()
                    .scaledToFill()
            } else if didFail {
                Circle()
                    .fill(FilmilaColors.surfaceElevated)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: size * 0.34, weight: .medium))
                            .foregroundStyle(FilmilaColors.textMuted)
                    }
            } else {
                Circle()
                    .fill(FilmilaColors.surfaceElevated)
                    .overlay {
                        ProgressView()
                            .tint(FilmilaColors.accent)
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(FilmilaColors.surfaceBright.opacity(0.85), lineWidth: 2)
        }
        .task(id: normalizedURLString) {
            await loadImageIfNeeded()
        }
    }

    private var initialsCircle: some View {
        Circle()
            .fill(FilmilaColors.surfaceElevated)
            .overlay {
                Text(initials)
                    .font(.system(size: size * 0.32, weight: .semibold, design: .rounded))
                    .foregroundStyle(FilmilaColors.accent)
            }
    }

    private func loadImageIfNeeded() async {
        await MainActor.run {
            loadedImage = nil
            didFail = false
        }

        guard let key = normalizedURLString, let remoteURL else { return }

        if let memoryHit = FilmilaImageMemoryCache.shared.image(forKey: key) {
            await MainActor.run { loadedImage = memoryHit }
            return
        }

        do {
            let (data, response) = try await FilmilaImageURLSession.shared.data(from: remoteURL)
            try Task.checkCancellation()
            guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
                await MainActor.run { didFail = true }
                return
            }
            guard let image = UIImage(data: data) else {
                await MainActor.run { didFail = true }
                return
            }
            FilmilaImageMemoryCache.shared.insert(image, forKey: key)
            await MainActor.run { loadedImage = image }
        } catch is CancellationError {
            return
        } catch {
            await MainActor.run { didFail = true }
        }
    }
}

#if DEBUG
#Preview {
    FilmHeroView(
        film: Film(
            id: 1,
            title: "Sample",
            description: "Desc",
            thumbnailUrl: "https://picsum.photos/seed/hero/1600/900",
            price: 0,
            status: .approved,
            genre: "Sci-Fi",
            duration: 7500,
            viewCount: 0,
            averageRating: 4.5,
            filmmaker: "megrenfilms@gmail.com",
            createdAt: Date()
        ),
        container: PreviewContainer(),
        averageRating: 4.5,
        ratingCount: 12,
        filmmaker: FilmmakerProfile(
            id: UUID(),
            displayName: "Megren Faleh",
            avatarUrl: "https://picsum.photos/seed/director/200/200"
        )
    )
    .preferredColorScheme(.dark)
}
#endif
