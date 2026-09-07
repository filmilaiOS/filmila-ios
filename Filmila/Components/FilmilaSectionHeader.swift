import SwiftUI

struct FilmilaSectionHeader: View {
    let title: String
    var systemImage: String?
    var accentTitle: Bool = false
    var trailingTitle: String?
    var trailingAction: (() -> Void)?

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FilmilaColors.accent)
            }

            Text(title)
                .font(.filmilaTitleSm)
                .foregroundStyle(accentTitle ? FilmilaColors.accent : FilmilaColors.textPrimary)

            Spacer(minLength: 0)

            if let trailingTitle, let trailingAction {
                Button(action: trailingAction) {
                    Text(trailingTitle)
                        .font(.filmilaCaptionMd)
                        .foregroundStyle(FilmilaColors.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.lg)
    }
}

#if DEBUG
#Preview {
    VStack(spacing: Spacing.lg) {
        FilmilaSectionHeader(
            title: "Continue Watching",
            systemImage: "clock.fill",
            accentTitle: true
        )
        FilmilaSectionHeader(
            title: "RECENT SEARCHES",
            trailingTitle: "Clear All",
            trailingAction: {}
        )
    }
    .padding(.vertical)
    .background(FilmilaColors.background)
    .preferredColorScheme(.dark)
}
#endif
