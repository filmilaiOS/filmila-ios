import SwiftUI

struct ComingSoonView: View {
    let title: String

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "sparkles")
                .font(.filmilaIconEmptyState)
                .foregroundStyle(FilmilaColors.accent)

            Text(title)
                .font(.filmilaTitleSm)
                .foregroundStyle(FilmilaColors.textPrimary)

            Text(String(localized: "shell_coming_soon_body"))
                .font(.filmilaBody)
                .foregroundStyle(FilmilaColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.xxl * 2)
    }
}

#if DEBUG
#Preview {
    ComingSoonView(title: "Collections")
        .background(FilmilaColors.background)
        .preferredColorScheme(.dark)
}
#endif
