import SwiftUI

struct DirectorProfileView: View {
    private let container: AppContainer

    @StateObject private var vm: DirectorProfileViewModel

    init(directorId: UUID, container: AppContainer) {
        self.container = container
        _vm = StateObject(wrappedValue: DirectorProfileViewModel(directorId: directorId, container: container))
    }

    var body: some View {
        Group {
            if let profile = vm.profile {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        header(profile)
                        statsRow
                        if let bio = profile.resolvedBio {
                            Text(bio)
                                .font(.filmilaBody)
                                .foregroundStyle(FilmilaColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        shareButton(profile)
                        filmsSection
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.xxl)
                }
            } else if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tint(FilmilaColors.accent)
            } else {
                unavailableState
            }
        }
        .background(FilmilaColors.background.ignoresSafeArea())
        .navigationTitle(vm.profile?.resolvedDisplayName ?? String(localized: "director_profile_title"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await vm.load()
        }
    }

    private func header(_ profile: FilmmakerProfile) -> some View {
        VStack(spacing: Spacing.md) {
            directorAvatar(profile)

            Text(profile.resolvedDisplayName)
                .font(.filmilaTitleSm)
                .foregroundStyle(FilmilaColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(String(localized: "detail_director"))
                .font(.filmilaLabel)
                .foregroundStyle(FilmilaColors.textMuted)
                .kerning(0.8)

            if let location = profile.resolvedLocation {
                Label(location, systemImage: "mappin.and.ellipse")
                    .font(.filmilaCaption)
                    .foregroundStyle(FilmilaColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.lg)
    }

    private func directorAvatar(_ profile: FilmmakerProfile) -> some View {
        Group {
            if let url = profile.resolvedAvatarURL {
                CachedAsyncImage(url: url)
                    .frame(width: 96, height: 96)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(FilmilaColors.surfaceElevated)
                    .frame(width: 96, height: 96)
                    .overlay {
                        Text(directorInitials(profile))
                            .font(.filmilaAvatarInitial)
                            .foregroundStyle(FilmilaColors.accent)
                    }
            }
        }
        .overlay {
            Circle()
                .stroke(FilmilaColors.surfaceBright, lineWidth: 2)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(
                value: vm.averageRating > 0 ? Film.formattedAverageRating(vm.averageRating) : "—",
                label: String(localized: "director_profile_stat_rating"),
                systemImage: "star.fill"
            )
            Divider()
                .frame(height: 36)
                .background(FilmilaColors.surfaceBright)
            statItem(
                value: formattedCount(vm.totalViews),
                label: String(localized: "director_profile_stat_views"),
                systemImage: "eye.fill"
            )
            Divider()
                .frame(height: 36)
                .background(FilmilaColors.surfaceBright)
            statItem(
                value: formattedCount(vm.filmCount),
                label: String(localized: "director_profile_stat_films"),
                systemImage: "film.fill"
            )
        }
        .padding(.vertical, Spacing.md)
        .background(FilmilaColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(FilmilaColors.surfaceBright.opacity(0.45), lineWidth: 1)
        )
    }

    private func statItem(value: String, label: String, systemImage: String) -> some View {
        VStack(spacing: Spacing.xs) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .semibold))
                Text(value)
                    .font(.filmilaBodyMedium)
            }
            .foregroundStyle(FilmilaColors.textPrimary)

            Text(label)
                .font(.filmilaCaption)
                .foregroundStyle(FilmilaColors.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private func shareButton(_ profile: FilmmakerProfile) -> some View {
        ShareLink(item: shareURL(for: profile)) {
            Label(String(localized: "director_profile_share"), systemImage: "square.and.arrow.up")
                .font(.filmilaBodyMedium)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(FilmilaPrimaryButtonStyle())
        .accessibilityLabel(Text(String(localized: "director_profile_share")))
    }

    private var filmsSection: some View {
        Group {
            if !vm.films.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text(String(localized: "director_profile_films_heading"))
                        .font(.filmilaLabel)
                        .foregroundStyle(FilmilaColors.textPrimary)
                        .tracking(2.2)

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .top, spacing: Spacing.md) {
                            ForEach(vm.films) { film in
                                NavigationLink {
                                    FilmDetailView(filmId: film.id, container: container)
                                } label: {
                                    FilmPosterCard(film: film, width: 130)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private var unavailableState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.filmilaIconHero)
                .foregroundStyle(FilmilaColors.textMuted)
            Text(String(localized: "director_profile_unavailable_title"))
                .font(.filmilaTitleSm)
                .foregroundStyle(FilmilaColors.textPrimary)
            Text(vm.errorMessage ?? String(localized: "director_profile_unavailable_body"))
                .font(.filmilaBody)
                .foregroundStyle(FilmilaColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func shareURL(for profile: FilmmakerProfile) -> URL {
        Env.apiBaseURL.appendingPathComponent("director/\(profile.id.uuidString.lowercased())", isDirectory: false)
    }

    private func directorInitials(_ profile: FilmmakerProfile) -> String {
        let source = profile.resolvedDisplayName
        let parts = source.split(separator: " ").map(String.init)
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(source.prefix(2)).uppercased()
    }

    private func formattedCount(_ value: Int) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000)
        }
        if value >= 1_000 {
            return String(format: "%.1fK", Double(value) / 1_000)
        }
        return "\(value)"
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        DirectorProfileView(
            directorId: UUID(uuidString: "0d6731eb-21ef-4598-9468-b90a41a6259c")!,
            container: PreviewContainer()
        )
    }
    .environmentObject(NetworkMonitor())
    .preferredColorScheme(.dark)
}
#endif
