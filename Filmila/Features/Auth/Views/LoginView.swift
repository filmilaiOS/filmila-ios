import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel: AuthViewModel

    init(authService: AuthServiceProtocol) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(authService: authService))
    }

    var body: some View {
        ZStack {
            AuthScreenChrome(
                title: String(localized: "auth_sign_in"),
                subtitle: String(localized: "auth_sign_in_subtitle")
            ) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    AuthFormField(title: String(localized: "auth_email")) {
                        TextField(String(localized: "auth_email"), text: $viewModel.email)
                            .textContentType(.username)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .foregroundStyle(FilmilaColors.textPrimary)
                            .disabled(viewModel.isLoading)
                    }

                    AuthFormField(title: String(localized: "auth_password")) {
                        SecureField(String(localized: "auth_password"), text: $viewModel.password)
                            .textContentType(.password)
                            .submitLabel(.go)
                            .foregroundStyle(FilmilaColors.textPrimary)
                            .onSubmit {
                                Task { await viewModel.login() }
                            }
                            .disabled(viewModel.isLoading)
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.filmilaCaption)
                            .foregroundStyle(FilmilaColors.destructive)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button {
                        Task { await viewModel.login() }
                    } label: {
                        Text(String(localized: "auth_sign_in"))
                            .font(.filmilaBodyMedium)
                    }
                    .buttonStyle(FilmilaPrimaryButtonStyle())
                    .disabled(viewModel.isLoading)
                    .padding(.top, Spacing.sm)

                    NavigationLink {
                        ForgotPasswordView()
                    } label: {
                        Text(String(localized: "auth_forgot_password"))
                            .font(.filmilaCaptionMd)
                            .foregroundStyle(FilmilaColors.accent)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(viewModel.isLoading)
                }
            }

            if viewModel.isLoading {
                VStack(spacing: Spacing.sm) {
                    ProgressView()
                        .scaleEffect(1.25)
                        .tint(FilmilaColors.accent)
                    Text(String(localized: "auth_signing_in"))
                        .font(.filmilaCaption)
                        .foregroundStyle(FilmilaColors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(FilmilaColors.background.opacity(0.55))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        LoginView(authService: PreviewContainer().authService)
    }
    .environment(\.container, PreviewContainer())
    .preferredColorScheme(.dark)
}
#endif
