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
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        TextField(String(localized: "auth_full_name"), text: $viewModel.fullName)
                            .textContentType(.name)
                            .textInputAutocapitalization(.words)
                            .padding()
                            .background(FilmilaColors.surface)
                            .cornerRadius(8)
                            .disabled(viewModel.isLoading)

                        TextField(String(localized: "auth_email"), text: $viewModel.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(FilmilaColors.surface)
                            .cornerRadius(8)
                            .disabled(viewModel.isLoading)

                        SecureField(String(localized: "auth_password"), text: $viewModel.password)
                            .textContentType(.newPassword)
                            .padding()
                            .background(FilmilaColors.surface)
                            .cornerRadius(8)
                            .disabled(viewModel.isLoading)

                        SecureField(String(localized: "auth_confirm_password"), text: $viewModel.confirmPassword)
                            .textContentType(.newPassword)
                            .padding()
                            .background(FilmilaColors.surface)
                            .cornerRadius(8)
                            .disabled(viewModel.isLoading)

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
                    }
                    .padding(Spacing.lg)
                }
            }

            if viewModel.isLoading && !viewModel.registrationPendingEmailVerification {
                ProgressView()
                    .scaleEffect(1.25)
                    .tint(FilmilaColors.accent)
            }
        }
        .navigationTitle(String(localized: "auth_register_title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CheckEmailNoticeView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: Spacing.md) {
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
