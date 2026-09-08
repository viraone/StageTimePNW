import Foundation
import Combine
import OSLog

/// Owns authentication state for the app. Screen-level validation and error
/// presentation live in the views/view models; this type only exposes
/// session state and the operations that change it.
@MainActor
final class AuthManager: ObservableObject {

    @Published private(set) var currentUser: AuthUser?
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isLoading = true
    /// Errors that arise outside any screen (e.g. deep-link verification).
    @Published var errorMessage: String?

    private let repository: AuthRepository

    init(repository: AuthRepository = SupabaseAuthRepository(), restoreOnInit: Bool = true) {
        self.repository = repository
        if restoreOnInit {
            Task { await checkSession() }
        }
    }

    // MARK: - Session

    func checkSession() async {
        isLoading = true
        defer { isLoading = false }

        let user = await repository.restoreSession()
        apply(user: user)
    }

    // MARK: - Sign up

    func signUp(email: String, password: String) async throws {
        try await repository.signUp(email: email, password: password)
        Log.auth.info("Account created for \(email, privacy: .private(mask: .hash))")
        apply(user: nil) // must verify email before first sign-in
    }

    // MARK: - Sign in

    func signIn(email: String, password: String) async throws {
        let user = try await repository.signIn(email: email, password: password)
        guard user.isEmailConfirmed else {
            apply(user: nil)
            throw AuthError.emailNotConfirmed
        }
        Log.auth.info("Signed in \(user.id, privacy: .private)")
        apply(user: user)
    }

    // MARK: - Sign out

    func signOut() async {
        do {
            try await repository.signOut()
        } catch {
            Log.auth.error("Sign-out failed: \(error.localizedDescription, privacy: .public)")
        }
        apply(user: nil)
    }

    // MARK: - Deep link

    static func isVerificationCallback(_ url: URL) -> Bool {
        url.scheme == "stagetimepnw" && url.host == "auth" && url.path == "/callback"
    }

    func handleDeepLink(url: URL) async {
        Log.auth.debug("Deep link received: \(url.absoluteString, privacy: .private)")

        guard Self.isVerificationCallback(url) else {
            errorMessage = AuthError.invalidDeepLink.errorDescription
            return
        }
        if let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
           items.contains(where: { $0.name.hasPrefix("error") }) {
            errorMessage = AuthError.deepLinkRejected.errorDescription
            return
        }

        do {
            let user = try await repository.session(fromCallback: url)
            apply(user: user)
            errorMessage = nil
            Log.auth.info("Verified via deep link \(user.id, privacy: .private)")
        } catch {
            errorMessage = String(localized: "Failed to verify email: \(error.localizedDescription)")
            Log.auth.error("Deep link failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Helpers

    private func apply(user: AuthUser?) {
        guard let user, user.isEmailConfirmed else {
            currentUser = nil
            isAuthenticated = false
            return
        }
        currentUser = user
        isAuthenticated = true
    }
}
