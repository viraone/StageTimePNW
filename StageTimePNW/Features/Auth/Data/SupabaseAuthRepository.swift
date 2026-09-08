import Foundation
import Supabase

struct SupabaseAuthRepository: AuthRepository {
    private let client: SupabaseClient
    private let emailRedirectURL: URL?

    init(
        client: SupabaseClient = supabase,
        emailRedirectURL: URL? = URL(string: "https://stagetimepnw.com/auth/callback.html")
    ) {
        self.client = client
        self.emailRedirectURL = emailRedirectURL
    }

    func restoreSession() async -> AuthUser? {
        guard let session = try? await client.auth.session else { return nil }
        return AuthUser(session.user)
    }

    func signUp(email: String, password: String) async throws {
        do {
            _ = try await client.auth.signUp(email: email, password: password, redirectTo: emailRedirectURL)
        } catch {
            throw AuthError.backend(message: error.localizedDescription)
        }
    }

    func signIn(email: String, password: String) async throws -> AuthUser {
        do {
            let session = try await client.auth.signIn(email: email, password: password)
            return AuthUser(session.user)
        } catch {
            throw AuthError.backend(message: error.localizedDescription)
        }
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func session(fromCallback url: URL) async throws -> AuthUser {
        do {
            let session = try await client.auth.session(from: url)
            return AuthUser(session.user)
        } catch {
            throw AuthError.backend(message: error.localizedDescription)
        }
    }
}

private extension AuthUser {
    init(_ user: User) {
        self.init(id: user.id, email: user.email, isEmailConfirmed: user.emailConfirmedAt != nil)
    }
}
