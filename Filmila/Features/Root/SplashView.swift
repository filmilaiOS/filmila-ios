import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            FilmilaColors.background.ignoresSafeArea()
            VStack(spacing: Spacing.lg) {
                Text(String(localized: "app_name"))
                    .font(.filmilaDisplay)
                    .foregroundStyle(FilmilaColors.accent)
                ProgressView()
                    .tint(FilmilaColors.accent)
            }
        }
    }
}

#if DEBUG
#Preview {
    SplashView()
        .environment(\.container, PreviewContainer())
        .preferredColorScheme(.dark)
}
#endif
