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

    // MARK: - Check Session
    
    /// Check if user already has a valid, confirmed session
    func checkSession() async {
        isLoading = true

        do {
            let session = try await supabase.auth.session
            let user = session.user

            // Only authenticate if the email has been confirmed
            if user.emailConfirmedAt != nil {
                self.currentUser = user
                self.isAuthenticated = true
            } else {
                self.currentUser = nil
                self.isAuthenticated = false
            }

        } catch {
            // No valid session
            self.currentUser = nil
            self.isAuthenticated = false
        }

        isLoading = false
    }

    // MARK: - Sign Up (Create Account)
    
    /// Create a new account with email and password
    func signUp(email: String, password: String) async throws {
        errorMessage = nil

        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                redirectTo: URL(string: "https://stagetimepnw.com/auth/callback.html")
            )

            print("✅ Account created for: \(email)")
            print("📧 Verification email sent")
            
            // Account created, but user must verify email before logging in
            self.currentUser = nil
            self.isAuthenticated = false

        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Sign In (Log In)
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        errorMessage = nil

        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )

            let user = session.user

            // Check if email is verified
            guard user.emailConfirmedAt != nil else {
                self.currentUser = nil
                self.isAuthenticated = false
                self.errorMessage = "Please verify your email before logging in. Check your inbox for the verification link."
                return
            }

            print("✅ User logged in: \(user.email ?? "unknown")")
            
            // User is logged in!
            self.currentUser = user
            self.isAuthenticated = true

        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Sign Out
    
    /// Sign out the current user
    func signOut() async {
        try? await supabase.auth.signOut()

        self.currentUser = nil
        self.isAuthenticated = false
    }
    
    // MARK: - Handle Deep Link
    
    /// Handle deep link from email verification (iOS only - bonus feature)
    /// Called when user clicks verification link on their iPhone
    /// This allows auto-login without entering password again
    func handleDeepLink(url: URL) async {
        print("📱 Deep link received: \(url.absoluteString)")
        
        // Validate the URL scheme, host, and path
        guard url.scheme == "stagetimepnw",
              url.host == "auth",
              url.path == "/callback" else {
            print("❌ Invalid deep link URL")
            self.errorMessage = "Invalid verification link"
            return
        }
        
        print("✅ URL validation passed")
        
        // Check for error parameters
        if let query = url.query, query.contains("error") {
            print("❌ Error in callback URL")
            self.errorMessage = "Verification link expired or invalid"
            return
        }
        
        do {
            // Let Supabase SDK handle the callback
            let session = try await supabase.auth.session(from: url)
            
            let user = session.user
            
            print("✅ User authenticated via deep link: \(user.email ?? "unknown")")
            print("✅ Session established and persisted")
            
            // User verified and auto-logged in!
            self.currentUser = user
            self.isAuthenticated = true
            
            // Clear any error messages
            self.errorMessage = nil
            
        } catch {
            self.errorMessage = "Failed to verify email: \(error.localizedDescription)"
            print("❌ Deep link error: \(error)")
        }
    }
}
