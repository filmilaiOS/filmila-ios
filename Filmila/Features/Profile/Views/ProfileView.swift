import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var auth: AuthService
    @Environment(\.container) private var container
    @Environment(\.openURL) private var openURL

    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("app_preferred_language") private var preferredLanguage = "en"

    @State private var isRestoringPurchases = false
    @State private var restoreErrorMessage: String?

    private static let privacyPolicyURL = URL(string: "https://filmila.com/privacy")!
    private static let termsOfServiceURL = URL(string: "https://filmila.com/terms")!

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                header

                settingsCard
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
        .background(FilmilaColors.background.ignoresSafeArea())
        .navigationTitle(String(localized: "profile_title"))
        .navigationBarTitleDisplayMode(.large)
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

    private var header: some View {
        VStack(spacing: Spacing.md) {
            avatar

            Text(displayName)
                .font(.filmilaTitleSm)
                .foregroundStyle(FilmilaColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(auth.userEmail ?? String(localized: "profile_email_placeholder"))
                .font(.filmilaCaption)
                .foregroundStyle(FilmilaColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.lg)
    }

    private var displayName: String {
        let trimmed = auth.profile?.fullName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmed.isEmpty {
            return trimmed
        }
        return String(localized: "profile_name_placeholder")
    }

    private var avatar: some View {
        let trimmedAvatar = auth.profile?.avatarUrl?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return ZStack {
            if !trimmedAvatar.isEmpty {
                CachedAsyncImage(url: trimmedAvatar)
                    .frame(width: 88, height: 88)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(FilmilaColors.surfaceElevated)
                    .frame(width: 88, height: 88)
                    .overlay {
                        Text(initials)
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

    private var initials: String {
        let source = auth.profile?.fullName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let source, !source.isEmpty {
            let parts = source.split(separator: " ").map(String.init)
            if parts.count >= 2 {
                let a = parts[0].prefix(1)
                let b = parts[1].prefix(1)
                return "\(a)\(b)".uppercased()
            }
            return String(source.prefix(2)).uppercased()
        }
        if let email = auth.userEmail, let ch = email.first {
            return String(ch).uppercased()
        }
        return "?"
    }

    private var settingsCard: some View {
        VStack(spacing: 0) {
            NavigationLink {
                NotificationsView(container: container)
            } label: {
                HStack {
                    Text(String(localized: "notifications_title"))
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

            Divider().background(FilmilaColors.surfaceBright)

            Toggle(String(localized: "profile_notifications"), isOn: $notificationsEnabled)
                .font(.filmilaBody)
                .foregroundStyle(FilmilaColors.textPrimary)
                .tint(FilmilaColors.accent)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)

            Divider().background(FilmilaColors.surfaceBright)

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

            Divider().background(FilmilaColors.surfaceBright)

            settingsButton(String(localized: "profile_privacy")) {
                openURL(Self.privacyPolicyURL)
            }

            Divider().background(FilmilaColors.surfaceBright)

            settingsButton(String(localized: "profile_terms")) {
                openURL(Self.termsOfServiceURL)
            }

            Divider().background(FilmilaColors.surfaceBright)

            Button {
                Task { await restorePurchases() }
            } label: {
                HStack {
                    Text(String(localized: "profile_restore_purchases"))
                        .font(.filmilaBody)
                        .foregroundStyle(FilmilaColors.textPrimary)
                    Spacer()
                    if isRestoringPurchases {
                        ProgressView()
                            .tint(FilmilaColors.accent)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)
            }
            .buttonStyle(.plain)
            .disabled(isRestoringPurchases)

            Divider().background(FilmilaColors.surfaceBright)

            Button {
                Task {
                    try? await auth.signOut()
                }
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
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(FilmilaColors.surfaceBright.opacity(0.45), lineWidth: 1)
        )
    }

    private func settingsButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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
        .buttonStyle(.plain)
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

#if DEBUG
#Preview {
    let container = PreviewContainer()
    NavigationStack {
        ProfileView()
    }
    .environment(\.container, container)
    .environmentObject(PreviewContainer.makeSignedInAuthForPreviews())
    .environmentObject(container.deepLinkHandler)
    .preferredColorScheme(.dark)
}
#endif
