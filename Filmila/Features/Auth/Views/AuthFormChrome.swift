import SwiftUI

struct AuthFormField<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.filmilaCaptionMd)
                .foregroundStyle(FilmilaColors.textSecondary)
            content()
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 14)
                .background(FilmilaColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(FilmilaColors.cardBorder, lineWidth: 1)
                )
        }
    }
}

struct AuthScreenChrome<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: () -> Content

    init(title: String, subtitle: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }

    var body: some View {
        ZStack {
            FilmilaColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack(spacing: 0) {
                            Text("Filmila")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(FilmilaColors.textPrimary)
                            Text(".")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(FilmilaColors.accent)
                        }

                        Text(title)
                            .font(.filmilaTitle)
                            .foregroundStyle(FilmilaColors.textPrimary)

                        if let subtitle {
                            Text(subtitle)
                                .font(.filmilaBody)
                                .foregroundStyle(FilmilaColors.textSecondary)
                        }
                    }
                    .padding(.top, Spacing.md)

                    content()
                }
                .padding(Spacing.lg)
            }
        }
    }
}

#if DEBUG
#Preview {
    AuthScreenChrome(title: "Sign In", subtitle: "Welcome back") {
        Text("Fields")
            .foregroundStyle(.white)
    }
    .preferredColorScheme(.dark)
}
#endif
