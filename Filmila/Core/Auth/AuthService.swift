import Combine
import Foundation
import Supabase

enum AuthServiceError: LocalizedError, Equatable {
    case viewerRoleRequired
    case profileNotFound

    var errorDescription: String? {
        switch self {
        case .viewerRoleRequired:
            return String(localized: "auth_error_viewer_only")
        case .profileNotFound:
            return String(localized: "auth_error_profile_not_found")
        }
    }
}

enum AuthViewerRoleValidator {
    /// Throws `AuthServiceError.viewerRoleRequired` when the profile role is not a viewer.
    static func requireViewerRole(_ rawRole: String) throws {
        let normalized = rawRole.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard normalized == "VIEWER" else {
            throw AuthServiceError.viewerRoleRequired
        }
    }
}

protocol AuthServiceProtocol: AnyObject {
    func login(email: String, password: String) async throws
    func register(email: String, password: String, fullName: String) async throws
    func restoreSession() async
    func signOut() async throws
    var session: Session? { get }
    var profile: Profile? { get }
    /// Convenience for UI (e.g. profile header).
    var userEmail: String? { get }
    var isLoading: Bool { get }
    var currentToken: String? { get }
}

final class AuthService: AuthServiceProtocol, ObservableObject {
    @Published private(set) var session: Session?
    @Published private(set) var profile: Profile?
    @Published private(set) var isLoading: Bool = true

    private let supabaseManager: SupabaseManager

#if DEBUG
    /// Overrides `userEmail` for SwiftUI previews when no `Session` is constructed.
    private var previewUserEmailOverride: String?
#endif

    init(supabaseManager: SupabaseManager = .shared) {
        self.supabaseManager = supabaseManager
    }

    var currentToken: String? {
        session?.accessToken
    }

    var userEmail: String? {
#if DEBUG
        if let previewUserEmailOverride { return previewUserEmailOverride }
#endif
        return session?.user.email
    }

#if DEBUG
    /// Applies a signed-in snapshot without touching Supabase (previews only).
    func applyPreviewSignedInState(userEmail: String, profile: Profile) {
        previewUserEmailOverride = userEmail
        self.session = nil
        self.profile = profile
        self.isLoading = false
    }

    func clearPreviewOverrides() {
        previewUserEmailOverride = nil
    }
#endif

    func login(email: String, password: String) async throws {
#if DEBUG
        await MainActor.run { self.previewUserEmailOverride = nil }
#endif
        let newSession = try await supabaseManager.client.auth.signIn(email: email, password: password)
        await MainActor.run { self.session = newSession }
        do {
            try await loadProfile(userId: newSession.user.id)
        } catch {
            await MainActor.run {
                self.session = nil
                self.profile = nil
            }
            throw error
        }
    }

    func register(email: String, password: String, fullName: String) async throws {
#if DEBUG
        await MainActor.run { self.previewUserEmailOverride = nil }
#endif
        let response = try await supabaseManager.client.auth.signUp(
            email: email,
            password: password,
            data: ["full_name": AnyJSON.string(fullName)]
        )
        if let newSession = response.session {
            await MainActor.run { self.session = newSession }
            do {
                try await loadProfile(userId: newSession.user.id)
            } catch {
                await MainActor.run {
                    self.session = nil
                    self.profile = nil
                }
                throw error
            }
        } else {
            await MainActor.run {
                self.session = nil
                self.profile = nil
            }
        }
    }

    func restoreSession() async {
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { self.isLoading = false } } }
        do {
            let current = try await supabaseManager.client.auth.session
            await MainActor.run { self.session = current }
            try await loadProfile(userId: current.user.id)
        } catch {
            await MainActor.run {
                self.session = nil
                self.profile = nil
            }
        }
    }

    func signOut() async throws {
#if DEBUG
        await MainActor.run { self.previewUserEmailOverride = nil }
#endif
        try await supabaseManager.client.auth.signOut()
        await MainActor.run {
            self.session = nil
            self.profile = nil
        }
    }

    private func loadProfile(userId: UUID) async throws {
        let loaded: Profile
        do {
            loaded = try await supabaseManager.client
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
        } catch {
            throw AuthServiceError.profileNotFound
        }

        do {
            try AuthViewerRoleValidator.requireViewerRole(loaded.role)
        } catch {
            try? await supabaseManager.client.auth.signOut()
            await MainActor.run {
                self.session = nil
                self.profile = nil
            }
            throw error
        }

        await MainActor.run { self.profile = loaded }
    }
}
