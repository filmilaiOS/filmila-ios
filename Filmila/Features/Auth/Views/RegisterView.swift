import SwiftUI

struct RegisterView: View {
    @StateObject private var viewModel: AuthViewModel

    init(authService: AuthServiceProtocol) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(authService: authService))
    }

    var body: some View {
        ZStack {
            FilmilaColors.background.ignoresSafeArea()

            if viewModel.registrationPendingEmailVerification {
                CheckEmailNoticeView(
                    title: String(localized: "auth_check_email_title"),
                    message: String(localized: "auth_check_email_register_body")
                )
                .padding(Spacing.lg)
            } else {
                AuthScreenChrome(
                    title: String(localized: "auth_register_title"),
                    subtitle: String(localized: "auth_register_subtitle")
                ) {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        AuthFormField(title: String(localized: "auth_full_name")) {
                            TextField(String(localized: "auth_full_name"), text: $viewModel.fullName)
                                .textContentType(.name)
                                .textInputAutocapitalization(.words)
                                .foregroundStyle(FilmilaColors.textPrimary)
                                .disabled(viewModel.isLoading)
                        }

                        AuthFormField(title: String(localized: "auth_email")) {
                            TextField(String(localized: "auth_email"), text: $viewModel.email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .foregroundStyle(FilmilaColors.textPrimary)
                                .disabled(viewModel.isLoading)
                        }

                        AuthFormField(title: String(localized: "auth_password")) {
                            SecureField(String(localized: "auth_password"), text: $viewModel.password)
                                .textContentType(.newPassword)
                                .foregroundStyle(FilmilaColors.textPrimary)
                                .disabled(viewModel.isLoading)
                        }

                        AuthFormField(title: String(localized: "auth_confirm_password")) {
                            SecureField(String(localized: "auth_confirm_password"), text: $viewModel.confirmPassword)
                                .textContentType(.newPassword)
                                .foregroundStyle(FilmilaColors.textPrimary)
                                .disabled(viewModel.isLoading)
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.filmilaCaption)
                                .foregroundStyle(FilmilaColors.destructive)
                        }

                        Button {
                            Task { await viewModel.register() }
                        } label: {
                            Text(String(localized: "auth_create_account"))
                                .font(.filmilaBodyMedium)
                        }
                        .buttonStyle(FilmilaPrimaryButtonStyle())
                        .disabled(viewModel.isLoading)
                        .padding(.top, Spacing.sm)
                    }
                }
            }

            if viewModel.isLoading && !viewModel.registrationPendingEmailVerification {
                ProgressView()
                    .scaleEffect(1.25)
                    .tint(FilmilaColors.accent)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct CheckEmailNoticeView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "envelope.badge")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(FilmilaColors.accent)
            Text(title)
                .font(.filmilaTitleSm)
                .foregroundStyle(FilmilaColors.textPrimary)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.filmilaBody)
                .foregroundStyle(FilmilaColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        RegisterView(authService: PreviewContainer().authService)
    }
    .environment(\.container, PreviewContainer())
    .preferredColorScheme(.dark)
}
#endif
