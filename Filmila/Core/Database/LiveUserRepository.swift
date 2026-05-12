import Foundation

/// Live container hook for viewer-scoped persistence (e.g. profile fields, device tokens).
/// Add Supabase calls here as product features grow; keeps `LiveAppContainer` free of empty stubs.
final class LiveUserRepository: UserRepositoryProtocol, @unchecked Sendable {
    init() {}
}
