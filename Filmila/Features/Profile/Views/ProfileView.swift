import SwiftUI

private enum ProfileActivityTab: String, CaseIterable, Identifiable {
    case history
    case watchlist
    case ratings
    case comments

    var id: String { rawValue }

    var title: String {
        switch self {
        case .history: String(localized: "profile_tab_history")
        case .watchlist: String(localized: "profile_tab_watchlist")
        case .ratings: String(localized: "profile_tab_ratings")
        case .comments: String(localized: "profile_tab_comments")
        }
    }

    var systemImage: String {
        switch self {
        case .history: "clock.fill"
        case .watchlist: "bookmark.fill"
        case .ratings: "star.fill"
        case .comments: "bubble.left.fill"
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject private var auth: AuthService
    @Environment(\.container) private var container
    @Environment(\.openURL) private var openURL

    @AppStorage(AppLanguage.storageKey) private var preferredLanguage = "en"

    @State private var selectedTab: ProfileActivityTab = .history
    @State private var historyItems: [ContinueWatchingItem] = []
    @State private var watchlistFilms: [Film] = []
    @State private var isLoadingActivity = false
    @State private var isRestoringPurchases = false
    @State private var restoreErrorMessage: String?

    private static let privacyPolicyURL = URL(string: "https://filmila.com/privacy")!
    private static let termsOfServiceURL = URL(string: "https://filmila.com/terms")!

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                profileHeaderCard
                activityTabBar
                activityContent
                accountManagementSection
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FilmilaColors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task(id: auth.session?.user.id) {
            await auth.refreshProfile()
            await loadActivityData()
        }
        .onChange(of: selectedTab) { _ in
            Task { await loadActivityData() }
        }
        .alert(String(localized: "profile_restore_error_title"), isPresented: Binding(
            get: { restoreErrorMessage != nil },
            set: { if !$0 { restoreErrorMessage = nil } }
        )) {
            Button(String(localized: "profile_ok"), role: .cancel) {
                restoreErrorMessage = nil
            }
        } message: {
            if let restoreErrorMessage {
                Text(restoreErrorMessage)
            }
        }
    }

    private var profileHeaderCard: some View {
        VStack(spacing: Spacing.md) {
            ZStack(alignment: .bottomTrailing) {
                avatar
                    .frame(width: 96, height: 96)

                Circle()
                    .fill(FilmilaColors.accent)
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .offset(x: 4, y: 4)
            }
            .padding(.top, Spacing.md)

            Text(displayName)
                .font(.filmilaTitle)
                .foregroundStyle(FilmilaColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(resolvedEmail)
                .font(.filmilaCaption)
                .foregroundStyle(FilmilaColors.textSecondary)
                .multilineTextAlignment(.center)

            if let roleLabel {
                Text(roleLabel)
                    .font(.filmilaCapsBadge)
                    .foregroundStyle(FilmilaColors.accent)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, 8)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(FilmilaColors.accent.opacity(0.6), lineWidth: 1)
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .background(FilmilaColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(FilmilaColors.cardBorder, lineWidth: 1)
        )
    }

    private var activityTabBar: some View {
        HStack(spacing: 4) {
            ForEach(ProfileActivityTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 12, weight: .semibold))
                        Text(tab.title)
                            .font(.filmilaCaptionMd)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(selectedTab == tab ? FilmilaColors.textInverse : FilmilaColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        Group {
                            if selectedTab == tab {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(FilmilaColors.accent)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(FilmilaColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private var activityContent: some View {
        if isLoadingActivity {
            ProgressView()
                .tint(FilmilaColors.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xl)
        } else {
            switch selectedTab {
            case .history:
                historyList
            case .watchlist:
                watchlistList
            case .ratings:
                profileEmptyState(
                    icon: "star",
                    message: String(localized: "profile_ratings_empty")
                )
            case .comments:
                profileEmptyState(
                    icon: "bubble.left",
                    message: String(localized: "profile_comments_empty")
                )
            }
        }
    }

    @ViewBuilder
    private var historyList: some View {
        if historyItems.isEmpty {
            profileEmptyState(icon: "clock", message: String(localized: "profile_history_empty"))
        } else {
            VStack(spacing: Spacing.sm) {
                ForEach(historyItems) { item in
                    NavigationLink {
                        FilmDetailView(filmId: item.film.id, container: container)
                    } label: {
                        ProfileHistoryRow(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var watchlistList: some View {
        if watchlistFilms.isEmpty {
            profileEmptyState(icon: "bookmark", message: String(localized: "library_empty_watchlist_subtitle"))
        } else {
            VStack(spacing: Spacing.sm) {
                ForEach(watchlistFilms.prefix(10)) { film in
                    NavigationLink {
                        FilmDetailView(filmId: film.id, container: container)
                    } label: {
                        SearchResultRowCard(film: film)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func profileEmptyState(icon: String, message: String) -> some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(FilmilaColors.textMuted)
            Text(message)
                .font(.filmilaBody)
                .foregroundStyle(FilmilaColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
    }

    private var accountManagementSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(String(localized: "profile_account_management"))
                .font(.filmilaLabel)
                .foregroundStyle(FilmilaColors.textMuted)
                .tracking(1.5)

            settingsCard
        }
        .padding(.top, Spacing.sm)
    }

    private var displayName: String {
        if let name = auth.profile?.resolvedDisplayName {
            return name
        }
        if let email = resolvedEmailIfAvailable {
            return emailDisplayName(from: email)
        }
        return String(localized: "profile_name_unknown")
    }

    private var roleLabel: String? {
        switch auth.profile?.normalizedRole {
        case "FILMMAKER":
            return String(localized: "profile_role_filmmaker_badge")
        case "VIEWER":
            return String(localized: "profile_role_viewer_badge")
        default:
            return nil
        }
    }

    private var resolvedEmail: String {
        resolvedEmailIfAvailable ?? String(localized: "profile_email_placeholder")
    }

    private var resolvedEmailIfAvailable: String? {
        let candidates = [auth.profile?.email, auth.userEmail]
        for candidate in candidates {
            let trimmed = candidate?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !trimmed.isEmpty { return trimmed }
        }
        return nil
    }

    private func emailDisplayName(from email: String) -> String {
        let local = email.split(separator: "@").first.map(String.init) ?? email
        return local.replacingOccurrences(of: ".", with: " ").capitalized
    }

    private var avatar: some View {
        let trimmedAvatar = auth.profile?.avatarUrl?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return Group {
            if !trimmedAvatar.isEmpty {
                CachedAsyncImage(url: trimmedAvatar)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(FilmilaColors.surfaceElevated)
                    .overlay {
                        Text(initials)
                            .font(.filmilaAvatarInitial)
                            .foregroundStyle(FilmilaColors.accent)
                    }
            }
        }
        .overlay {
            Circle()
                .stroke(FilmilaColors.accent.opacity(0.35), lineWidth: 2)
        }
    }

    private var initials: String {
        if let name = auth.profile?.resolvedDisplayName {
            let parts = name.split(separator: " ").map(String.init)
            if parts.count >= 2 {
                return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
            }
            return String(name.prefix(2)).uppercased()
        }
        if let email = resolvedEmailIfAvailable, let ch = email.first {
            return String(ch).uppercased()
        }
        return "?"
    }

    private var settingsCard: some View {
        VStack(spacing: 0) {
            NavigationLink {
                NotificationsView(container: container)
            } label: {
                settingsRowLabel(String(localized: "notifications_title"))
            }

            settingsDivider

            HStack {
                Text(String(localized: "profile_language"))
                    .font(.filmilaBody)
                    .foregroundStyle(FilmilaColors.textPrimary)
                Spacer()
                Picker("", selection: $preferredLanguage) {
                    Text(String(localized: "profile_lang_english")).tag("en")
                    Text(String(localized: "profile_lang_arabic")).tag("ar")
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .tint(FilmilaColors.accent)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)

            settingsDivider

            settingsButton(String(localized: "profile_privacy")) {
                openURL(Self.privacyPolicyURL)
            }

            settingsDivider

            settingsButton(String(localized: "profile_terms")) {
                openURL(Self.termsOfServiceURL)
            }

            settingsDivider

            Button {
                Task { await restorePurchases() }
            } label: {
                HStack {
                    Text(String(localized: "profile_restore_purchases"))
                        .font(.filmilaBody)
                        .foregroundStyle(FilmilaColors.textPrimary)
                    Spacer()
                    if isRestoringPurchases {
                        ProgressView().tint(FilmilaColors.accent)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)
            }
            .buttonStyle(.plain)
            .disabled(isRestoringPurchases)

            settingsDivider

            Button {
                Task { try? await auth.signOut() }
            } label: {
                Text(String(localized: "profile_sign_out"))
                    .font(.filmilaBodyMedium)
                    .foregroundStyle(FilmilaColors.destructive)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.md)
            }
            .buttonStyle(.plain)
        }
        .background(FilmilaColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(FilmilaColors.cardBorder, lineWidth: 1)
        )
    }

    private var settingsDivider: some View {
        Divider().background(FilmilaColors.surfaceBright)
    }

    private func settingsRowLabel(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.filmilaBody)
                .foregroundStyle(FilmilaColors.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.filmilaCapsBadge)
                .foregroundStyle(FilmilaColors.textMuted)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
    }

    private func settingsButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            settingsRowLabel(title)
        }
        .buttonStyle(.plain)
    }

    private func loadActivityData() async {
        isLoadingActivity = true
        defer { isLoadingActivity = false }

        watchlistFilms = (try? await container.filmsRepo.fetchWatchlist()) ?? []

        let progressRows = (try? await container.progressRepo.fetchContinueWatching()) ?? []
        var resolved: [ContinueWatchingItem] = []
        for progress in progressRows where !progress.isCompleted {
            if let film = try? await container.filmsRepo.fetchFilm(id: progress.filmId) {
                resolved.append(ContinueWatchingItem(film: film, progress: progress))
            }
        }
        historyItems = resolved
    }

    private func restorePurchases() async {
        isRestoringPurchases = true
        defer { isRestoringPurchases = false }
        do {
            try await container.iapService.restorePurchases()
        } catch {
            restoreErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

private struct ProfileHistoryRow: View {
    let item: ContinueWatchingItem

    private var progressLabel: String {
        guard let duration = item.film.duration, duration > 0 else {
            return String(localized: "profile_history_watched")
        }
        let watchedMinutes = item.progress.progressSeconds / 60
        let totalMinutes = duration / 60
        return String(format: String(localized: "profile_history_progress_format"), watchedMinutes, totalMinutes)
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            CachedAsyncImage(url: item.film.thumbnailUrl)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.film.displayTitle)
                    .font(.filmilaBodyMedium)
                    .foregroundStyle(FilmilaColors.textPrimary)
                    .lineLimit(1)
                Text(progressLabel)
                    .font(.filmilaCaption)
                    .foregroundStyle(FilmilaColors.textSecondary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.filmilaCapsBadge)
                .foregroundStyle(FilmilaColors.textMuted)
        }
        .padding(Spacing.md)
        .background(FilmilaColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#if DEBUG
#Preview {
    let container = PreviewContainer()
    NavigationStack {
        ProfileView()
    }
    .environment(\.container, container)
    .environmentObject(PreviewContainer.makeSignedInAuthForPreviews())
    .preferredColorScheme(.dark)
}
#endif
