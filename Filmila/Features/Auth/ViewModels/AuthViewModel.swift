import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var fullName = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var registrationPendingEmailVerification = false

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    func login() async {
        errorMessage = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            errorMessage = String(localized: "auth_error_email_empty")
            return
        }
        guard !password.isEmpty else {
            errorMessage = String(localized: "auth_error_password_empty")
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            try await authService.login(email: trimmedEmail, password: password)
        } catch {
            errorMessage = Self.userFacingMessage(for: error)
        }
    }

    func register() async {
        errorMessage = nil
        registrationPendingEmailVerification = false

        let name = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.isEmpty else {
            errorMessage = String(localized: "auth_error_name_empty")
            return
        }
        guard !trimmedEmail.isEmpty else {
            errorMessage = String(localized: "auth_error_email_empty")
            return
        }
        guard trimmedEmail.isValidEmail else {
            errorMessage = String(localized: "auth_error_email_invalid")
            return
        }
        guard password == confirmPassword else {
            errorMessage = String(localized: "auth_error_passwords_mismatch")
            return
        }
        guard !password.isEmpty else {
            errorMessage = String(localized: "auth_error_password_empty")
            return
        }

        isLoading = true
        defer { isLoading = false }
        do {
            try await authService.register(email: trimmedEmail, password: password, fullName: name)
            if authService.session == nil {
                registrationPendingEmailVerification = true
            }
        } catch {
            errorMessage = Self.userFacingMessage(for: error)
        }
    }

    private static func userFacingMessage(for error: Error) -> String {
        if let localized = error as? LocalizedError,
           let description = localized.errorDescription?.trimmingCharacters(in: .whitespacesAndNewlines),
           !description.isEmpty {
            return description
        }
        let fallback = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !fallback.isEmpty {
            return fallback
        }
        return String(localized: "auth_error_request_failed")
    }
}

private extension String {
    var isValidEmail: Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
}
