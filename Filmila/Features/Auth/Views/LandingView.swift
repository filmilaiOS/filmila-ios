import SwiftUI

struct LandingView: View {
    @Environment(\.container) private var container
    @EnvironmentObject private var auth: AuthService

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    FilmilaColors.playerChrome,
                    FilmilaColors.landingGradientBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Text(String(localized: "app_name"))
                    .font(.filmilaDisplay)
                    .foregroundStyle(FilmilaColors.accent)

                Text(String(localized: "landing_tagline"))
                    .font(.filmilaCaption)
                    .foregroundStyle(FilmilaColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.sm)

                Spacer()

                VStack(spacing: Spacing.md) {
                    NavigationLink {
                        LoginView(authService: auth)
                    } label: {
                        Text(String(localized: "auth_sign_in"))
                            .font(.filmilaBodyMedium)
                    }
                    .buttonStyle(FilmilaPrimaryButtonStyle())
                    .padding(.horizontal, Spacing.lg)

                    NavigationLink {
                        RegisterView(authService: auth)
                    } label: {
                        Text(String(localized: "auth_create_account_link"))
                            .font(.filmilaBodyMedium)
                            .foregroundStyle(FilmilaColors.accent)
                    }
                    .padding(.bottom, Spacing.xl)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        LandingView()
    }
    .environment(\.container, PreviewContainer())
    .environmentObject(AuthService())
    .preferredColorScheme(.dark)
}
#endif
