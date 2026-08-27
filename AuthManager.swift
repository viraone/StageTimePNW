import SwiftUI
import Supabase
import Combine

@MainActor
class AuthManager: ObservableObject {

    @Published var currentUser: User? = nil
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = true
    @Published var errorMessage: String? = nil

    init() {
        Task {
            await checkSession()
        }
    }

    // Check if user already has a VALID, CONFIRMED session
    func checkSession() async {
        isLoading = true

        do {
            let session = try await supabase.auth.session
            let user = session.user

            // Only authenticate if the email has actually been confirmed
            if user.emailConfirmedAt != nil {
                self.currentUser = user
                self.isAuthenticated = true
            } else {
                self.currentUser = nil
                self.isAuthenticated = false
            }

        } catch {
            self.currentUser = nil
            self.isAuthenticated = false
        }

        isLoading = false
    }

    // Create a new account
    func signUp(email: String, password: String) async throws {
        errorMessage = nil

        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password
            )

            // Signup succeeded, but DO NOT log them into the app yet.
            // They must confirm their email first.
            self.currentUser = nil
            self.isAuthenticated = false

        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }

    // Sign in to existing account
    func signIn(email: String, password: String) async throws {
        errorMessage = nil

        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )

            let user = session.user

            guard user.emailConfirmedAt != nil else {
                self.currentUser = nil
                self.isAuthenticated = false
                self.errorMessage = "Please verify your email before logging in."
                return
            }

            self.currentUser = user
            self.isAuthenticated = true

        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }

    // Sign Out
    func signOut() async {
        try? await supabase.auth.signOut()

        self.currentUser = nil
        self.isAuthenticated = false
    }
}
