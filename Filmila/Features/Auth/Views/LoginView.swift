import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel: AuthViewModel

    init(authService: AuthServiceProtocol) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(authService: authService))
    }

    var body: some View {
        ZStack {
            FilmilaColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    TextField(String(localized: "auth_email"), text: $viewModel.email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .padding()
                        .background(FilmilaColors.surface)
                        .cornerRadius(8)
                        .disabled(viewModel.isLoading)

                    SecureField(String(localized: "auth_password"), text: $viewModel.password)
                        .textContentType(.password)
                        .submitLabel(.go)
                        .onSubmit {
                            Task { await viewModel.login() }
                        }
                        .padding()
                        .background(FilmilaColors.surface)
                        .cornerRadius(8)
                        .disabled(viewModel.isLoading)

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

                    NavigationLink {
                        ForgotPasswordView()
                    } label: {
                        Text(String(localized: "auth_forgot_password"))
                            .font(.filmilaCaption)
                            .foregroundStyle(FilmilaColors.accent)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(viewModel.isLoading)
                }
                .padding(Spacing.lg)
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
            }
        }
        .navigationTitle(String(localized: "auth_sign_in"))
        .navigationBarTitleDisplayMode(.inline)
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
