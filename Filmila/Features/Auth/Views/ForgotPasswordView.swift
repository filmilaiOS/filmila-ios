import SwiftUI

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var didSucceed = false

    var body: some View {
        ZStack {
            FilmilaColors.background.ignoresSafeArea()

            if didSucceed {
                CheckEmailNoticeView(
                    title: String(localized: "auth_check_email_title"),
                    message: String(localized: "auth_check_email_reset_body")
                )
                .padding(Spacing.lg)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        TextField(String(localized: "auth_email"), text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(FilmilaColors.surface)
                            .cornerRadius(8)
                            .disabled(isLoading)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.filmilaCaption)
                                .foregroundStyle(FilmilaColors.destructive)
                        }

                        Button {
                            Task { await sendReset() }
                        } label: {
                            Text(String(localized: "auth_send_reset"))
                                .font(.filmilaBodyMedium)
                        }
                        .buttonStyle(FilmilaPrimaryButtonStyle())
                        .disabled(isLoading)
                    }
                    .padding(Spacing.lg)
                }
            }

            if isLoading && !didSucceed {
                ProgressView()
                    .scaleEffect(1.25)
                    .tint(FilmilaColors.accent)
            }
        }
        .navigationTitle(String(localized: "auth_forgot_password"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sendReset() async {
        errorMessage = nil
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = String(localized: "auth_error_email_empty")
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            try await SupabaseManager.shared.client.auth.resetPasswordForEmail(trimmed, redirectTo: nil)
            didSucceed = true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ForgotPasswordView()
    }
    .environment(\.container, PreviewContainer())
    .preferredColorScheme(.dark)
}
#endif
