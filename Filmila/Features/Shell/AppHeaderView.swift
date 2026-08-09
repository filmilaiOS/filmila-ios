import SwiftUI

struct AppHeaderView: View {
    var showsMenuButton: Bool = true
    var onMenuTap: () -> Void = {}

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image("FilmilaLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 28)
                .accessibilityLabel(Text(String(localized: "app_name")))

            Spacer(minLength: 0)

            if showsMenuButton {
                Button(action: onMenuTap) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(FilmilaColors.textPrimary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(String(localized: "shell_menu_open")))
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.sm)
        .background(FilmilaColors.background)
    }
}

#if DEBUG
#Preview {
    AppHeaderView(onMenuTap: {})
        .background(FilmilaColors.background)
        .preferredColorScheme(.dark)
}
#endif
