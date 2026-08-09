import SwiftUI

struct MenuDrawerView: View {
    @EnvironmentObject private var auth: AuthService
    @Environment(\.shellNavigation) private var shellNavigation

    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(FilmilaColors.textSecondary)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(String(localized: "shell_menu_close")))
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if auth.session == nil {
                        authButtons
                    }

                    browseSection

                    submitFilmCard

                    footerSection
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(FilmilaColors.surface)
    }

    private var authButtons: some View {
        HStack(spacing: Spacing.sm) {
            Button {
                onClose()
                shellNavigation.presentLogin()
            } label: {
                Text(String(localized: "auth_sign_in"))
                    .font(.filmilaBodyMedium)
            }
            .buttonStyle(FilmilaWhiteButtonStyle())

            Button {
                onClose()
                shellNavigation.presentRegister()
            } label: {
                Text(String(localized: "auth_create_account_link"))
                    .font(.filmilaBodyMedium)
            }
            .buttonStyle(FilmilaWhiteOutlineButtonStyle())
        }
        .padding(.top, Spacing.sm)
    }

    private var browseSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "shell_browse_heading"))
                .font(.filmilaLabel)
                .foregroundStyle(FilmilaColors.textMuted)
                .tracking(1.6)
                .padding(.bottom, Spacing.xs)

            drawerLink(String(localized: "shell_browse_films")) {
                shellNavigation.navigateBrowse(.films)
            }
            drawerLink(String(localized: "shell_browse_collections")) {
                shellNavigation.navigateBrowse(.collections)
            }
            drawerLink(String(localized: "shell_browse_genres")) {
                shellNavigation.navigateBrowse(.genres)
            }
            drawerLink(String(localized: "shell_browse_moods")) {
                shellNavigation.navigateBrowse(.moods)
            }
            drawerLink(String(localized: "shell_browse_themes")) {
                shellNavigation.navigateBrowse(.themes)
            }
            drawerLink(String(localized: "shell_browse_my_list")) {
                shellNavigation.navigateBrowse(.myList)
            }
            drawerLink(String(localized: "tab_community")) {
                shellNavigation.navigateBrowse(.community)
            }
        }
    }

    private var submitFilmCard: some View {
        Button {
            onClose()
            shellNavigation.navigateBrowse(.submitFilm)
        } label: {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(String(localized: "shell_submit_film_title"))
                    .font(.filmilaBodyMedium)
                    .foregroundStyle(FilmilaColors.textPrimary)
                Text(String(localized: "shell_submit_film_subtitle"))
                    .font(.filmilaCaption)
                    .foregroundStyle(FilmilaColors.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .background(FilmilaColors.accentSubtle)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(FilmilaColors.accent.opacity(0.35), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var footerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if auth.session != nil {
                drawerLink(String(localized: "tab_profile")) {
                    shellNavigation.navigateBrowse(.profile)
                }
            }

            drawerLink(String(localized: "shell_about_filmila")) {
                shellNavigation.navigateBrowse(.about)
            }
            drawerLink(String(localized: "shell_partners")) {
                shellNavigation.navigateBrowse(.partners)
            }
            drawerLink(String(localized: "shell_help_center")) {
                shellNavigation.navigateBrowse(.help)
            }
        }
        .padding(.top, Spacing.md)
    }

    private func drawerLink(_ title: String, action: @escaping () -> Void) -> some View {
        Button {
            onClose()
            action()
        } label: {
            Text(title)
                .font(.filmilaBody)
                .foregroundStyle(FilmilaColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    MenuDrawerView(onClose: {})
        .frame(width: 320)
        .environmentObject(PreviewContainer.makeSignedInAuthForPreviews())
        .environment(\.shellNavigation, ShellNavigationActions())
        .preferredColorScheme(.dark)
}
#endif
