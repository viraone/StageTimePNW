import Foundation

/// App-level view of an authenticated user, independent of the auth vendor.
struct AuthUser: Equatable, Sendable {
    let id: UUID
    let email: String?
    let isEmailConfirmed: Bool
}

enum AuthError: LocalizedError, Equatable {
    case emailNotConfirmed
    case invalidDeepLink
    case deepLinkRejected
    case backend(message: String)

    var errorDescription: String? {
        switch self {
        case .emailNotConfirmed:
            return String(localized: "Please verify your email before logging in. Check your inbox for the verification link.")
        case .invalidDeepLink:
            return String(localized: "Invalid verification link")
        case .deepLinkRejected:
            return String(localized: "Verification link expired or invalid")
        case .backend(let message):
            return message
        }
    }
}

/// Boundary between the app and the authentication backend. Views and view
/// models depend on this protocol so they can be exercised with a fake.
protocol AuthRepository: Sendable {
    /// Returns the persisted session's user, or nil when signed out.
    func restoreSession() async -> AuthUser?
    func signUp(email: String, password: String) async throws
    func signIn(email: String, password: String) async throws -> AuthUser
    func signOut() async throws
    /// Exchanges an email-verification callback URL for a session.
    func session(fromCallback url: URL) async throws -> AuthUser
}
