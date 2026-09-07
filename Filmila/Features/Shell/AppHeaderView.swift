import SwiftUI

struct AppHeaderView: View {
    @EnvironmentObject private var auth: AuthService
    @Environment(\.mainTabSelection) private var mainTabSelection
    @Environment(\.shellNavigation) private var shellNavigation

    var onMenuTap: () -> Void = {}

    private enum TabIndex {
        static let search = 1
        static let profile = 3
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            Button(action: onMenuTap) {
                HStack(spacing: 0) {
                    Text("Filmila")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(FilmilaColors.textPrimary)
                    Text(".")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(FilmilaColors.accent)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(String(localized: "app_name")))

            Spacer(minLength: 0)

            headerIconButton(systemName: "magnifyingglass") {
                mainTabSelection?.wrappedValue = TabIndex.search
            }
            .accessibilityLabel(Text(String(localized: "tab_search")))

            Button {
                if auth.session != nil {
                    mainTabSelection?.wrappedValue = TabIndex.profile
                } else {
                    shellNavigation.presentLogin()
                }
            } label: {
                headerProfileAvatar
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(String(localized: "tab_profile")))
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.sm)
        .background(FilmilaColors.background)
    }

    private func headerIconButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(FilmilaColors.textPrimary)
                .frame(width: 40, height: 40)
                .background(FilmilaColors.surfaceElevated)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(FilmilaColors.cardBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var headerProfileAvatar: some View {
        let trimmedAvatar = auth.profile?.avatarUrl?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedAvatar.isEmpty {
            CachedAsyncImage(url: trimmedAvatar)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(FilmilaColors.accent.opacity(0.35), lineWidth: 1.5)
                )
        } else {
            Circle()
                .fill(FilmilaColors.surfaceElevated)
                .frame(width: 40, height: 40)
                .overlay {
                    Text(profileInitials)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(FilmilaColors.accent)
                }
                .overlay(
                    Circle()
                        .stroke(FilmilaColors.cardBorder, lineWidth: 1)
                )
        }
    }

    private var profileInitials: String {
        if let name = auth.profile?.resolvedDisplayName {
            let parts = name.split(separator: " ").map(String.init)
            if parts.count >= 2 {
                return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
            }
            return String(name.prefix(2)).uppercased()
        }
        if let email = auth.userEmail?.first {
            return String(email).uppercased()
        }
        return "?"
    }
}

#if DEBUG
#Preview {
    AppHeaderView(onMenuTap: {})
        .environmentObject(PreviewContainer.makeSignedInAuthForPreviews())
        .background(FilmilaColors.background)
        .preferredColorScheme(.dark)
}
#endif
