import Combine
import Foundation
import Supabase

private func isTransientNetworkFailure(_ error: Error) -> Bool {
    if error is CancellationError { return true }
    if error is URLError { return true }
    let ns = error as NSError
    if ns.domain == NSURLErrorDomain { return true }
    if let underlying = ns.userInfo[NSUnderlyingErrorKey] as? Error {
        return isTransientNetworkFailure(underlying)
    }
    return false
}

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
    /// Throws `AuthServiceError.viewerRoleRequired` when the profile role is not allowed for this app.
    static func requireAllowedProfileRole(_ rawRole: String) throws {
        let normalized = rawRole.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard normalized == "VIEWER" || normalized == "FILMMAKER" else {
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
    /// Reloads `profile` from Supabase when a session exists (e.g. profile sheet opened).
    func refreshProfile() async
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

    /// Updates the published session after a Supabase SDK refresh triggered outside AuthService (e.g. APIClient).
    @MainActor
    func syncPublishedSession(_ session: Session) {
#if DEBUG
        print("[FilmilaAuth] session synced from external refresh (APIClient) userId=\(session.user.id.uuidString)")
#endif
        self.session = session
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
#if DEBUG
            let publishedSession = await MainActor.run { self.session }
            let role = await MainActor.run { self.profile?.role ?? "(no profile yet)" }
            print("[FilmilaAuth] login succeeded — userId=\(newSession.user.id.uuidString) publishedSession=\(publishedSession != nil ? "set" : "nil") profile.role=\(role)")
#endif
        } catch {
            await MainActor.run {
                self.clearPublishedAuthState(reason: "login loadProfile failed")
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
                    self.clearPublishedAuthState(reason: "register loadProfile failed")
                }
                throw error
            }
        } else {
            await MainActor.run {
                self.clearPublishedAuthState(reason: "register pending email verification (no session)")
            }
        }
    }

    func restoreSession() async {
#if DEBUG
        print("[FilmilaAuth] restoreSession ENTER instance=\(ObjectIdentifier(self))")
#endif
        await MainActor.run { isLoading = true }
        defer {
            Task { @MainActor in
                self.isLoading = false
#if DEBUG
                print("[FilmilaAuth] restoreSession EXIT instance=\(ObjectIdentifier(self)) sessionNil=\(self.session == nil)")
#endif
            }
        }

        let current: Session
        do {
            var session = try await supabaseManager.client.auth.session
            if session.isExpired {
                do {
                    session = try await supabaseManager.client.auth.refreshSession()
                } catch {
#if DEBUG
                    print("[FilmilaAuth] restoreSession refresh failed (expired session): \(error)")
#endif
                    await MainActor.run {
                        self.clearPublishedAuthState(reason: "restoreSession token refresh failed")
                    }
                    return
                }
            }
            current = session
        } catch is CancellationError {
#if DEBUG
            print("[FilmilaAuth] restoreSession cancelled while reading client.session")
#endif
            return
        } catch {
#if DEBUG
            print("[FilmilaAuth] restoreSession no stored session / error: \(error) — clearing local session state")
#endif
            await MainActor.run {
                self.clearPublishedAuthState(reason: "restoreSession no stored client.session")
            }
            return
        }

        await MainActor.run { self.session = current }
#if DEBUG
        print("[FilmilaAuth] restoreSession loaded client.session userId=\(current.user.id.uuidString)")
#endif

        do {
            try await loadProfile(userId: current.user.id)
        } catch is CancellationError {
#if DEBUG
            print("[FilmilaAuth] restoreSession cancelled during loadProfile")
#endif
            return
        } catch {
            // Keep the Supabase session on flaky networks so a successful sign-in is not wiped.
            if isTransientNetworkFailure(error) {
#if DEBUG
                print("[FilmilaAuth] restoreSession loadProfile transient error, keeping session: \(error)")
#endif
                return
            }
#if DEBUG
            print("[FilmilaAuth] restoreSession loadProfile failed — clearing session: \(error)")
#endif
            await MainActor.run {
                self.clearPublishedAuthState(reason: "restoreSession loadProfile failed (non-transient)")
            }
        }
    }

    func signOut() async throws {
#if DEBUG
        await MainActor.run { self.previewUserEmailOverride = nil }
#endif
        try await supabaseManager.client.auth.signOut()
        await MainActor.run {
            clearPublishedAuthState(reason: "signOut() user initiated")
        }
    }

    func refreshProfile() async {
        let userId = await MainActor.run { session?.user.id }
        guard let userId else { return }
        do {
            try await loadProfile(userId: userId)
        } catch {
#if DEBUG
            print("[FilmilaAuth] refreshProfile failed (session kept): \(error)")
#endif
        }
    }

    @MainActor
    private func clearPublishedAuthState(reason: String, file: StaticString = #fileID, line: UInt = #line) {
#if DEBUG
        print("[FilmilaAuth] session cleared by: \(reason) (\(file):\(line))")
#endif
        session = nil
        profile = nil
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
            if isTransientNetworkFailure(error) { throw error }
            throw AuthServiceError.profileNotFound
        }

#if DEBUG
        print("[FilmilaAuth] loadProfile raw role from Supabase (before role guard): \(String(reflecting: loaded.role))")
#endif

        do {
            try AuthViewerRoleValidator.requireAllowedProfileRole(loaded.role)
        } catch {
            try? await supabaseManager.client.auth.signOut()
            await MainActor.run {
                self.clearPublishedAuthState(reason: "loadProfile disallowed role")
            }
            throw error
        }

        await MainActor.run { self.profile = loaded }
    }
}
