import SwiftUI

struct SignUpView: View {

    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isSubmitting: Bool = false
    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    @State private var successMessage: String? = nil

    var body: some View {

        ZStack {

            // Background: Misty forest/mountain aesthetic (matching LoginView)
            LinearGradient(
                colors: [
                    Color(red: 0.42, green: 0.53, blue: 0.51),
                    Color(red: 0.28, green: 0.38, blue: 0.38),
                    Color(red: 0.18, green: 0.25, blue: 0.26)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Subtle pattern overlay
            Color.black.opacity(0.05)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {

                VStack(spacing: 0) {

                    Spacer(minLength: 60)

                    // MARK: - Branding Header

                    VStack(spacing: 8) {
                        
                        Text("STAGE TIME PNW")
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(.white)
                            .tracking(2)
                    }
                    .padding(.bottom, 30)

                    // MARK: - Title

                    Text("Create your account")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 30)

                    // MARK: - Input Fields

                    VStack(spacing: 16) {

                        // Email Field with Custom White Placeholder
                        ZStack(alignment: .leading) {
                            if email.isEmpty {
                                Text("Email")
                                    .foregroundColor(.white.opacity(0.5))
                                    .font(.system(size: 15))
                                    .padding(.horizontal, 20)
                            }
                            TextField("", text: $email)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .textContentType(.emailAddress)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                        }
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )

                        // Password Field with Custom White Placeholder
                        ZStack(alignment: .leading) {
                            if password.isEmpty && !showPassword {
                                Text("Password")
                                    .foregroundColor(.white.opacity(0.5))
                                    .font(.system(size: 15))
                                    .padding(.horizontal, 20)
                            }
                            
                            HStack {
                                Group {
                                    if showPassword {
                                        TextField("", text: $password)
                                            .textContentType(.newPassword)
                                    } else {
                                        SecureField("", text: $password)
                                            .textContentType(.newPassword)
                                    }
                                }
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .autocapitalization(.none)
                                
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye" : "eye.slash")
                                        .foregroundColor(.white.opacity(0.6))
                                        .font(.system(size: 16))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )

                        // Confirm Password Field with Custom White Placeholder
                        ZStack(alignment: .leading) {
                            if confirmPassword.isEmpty && !showConfirmPassword {
                                Text("Confirm Password")
                                    .foregroundColor(.white.opacity(0.5))
                                    .font(.system(size: 15))
                                    .padding(.horizontal, 20)
                            }
                            
                            HStack {
                                Group {
                                    if showConfirmPassword {
                                        TextField("", text: $confirmPassword)
                                            .textContentType(.newPassword)
                                    } else {
                                        SecureField("", text: $confirmPassword)
                                            .textContentType(.newPassword)
                                    }
                                }
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .autocapitalization(.none)
                                
                                Button(action: { showConfirmPassword.toggle() }) {
                                    Image(systemName: showConfirmPassword ? "eye" : "eye.slash")
                                        .foregroundColor(.white.opacity(0.6))
                                        .font(.system(size: 16))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 32)

                    // MARK: - Success Message

                    if let successMessage {

                        VStack(spacing: 8) {

                            Image(systemName: "envelope.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color(red: 0.65, green: 0.78, blue: 0.73))

                            Text(successMessage)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 16)
                    }

                    // MARK: - Error Message Display

                    if let error = authManager.errorMessage {

                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 16)
                    }

                    // MARK: - Create Account Button

                    Button(action: handleSignUp) {

                        if isSubmitting {

                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)

                        } else {

                            Text("Create Account")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(red: 0.18, green: 0.25, blue: 0.26))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                    }
                    .background(Color(red: 0.65, green: 0.78, blue: 0.73))
                    .cornerRadius(12)
                    .padding(.horizontal, 32)
                    .padding(.top, 24)
                    .disabled(isSubmitting)

                    // Privacy Policy Text
                    Text("By creating an account, you accept our Privacy Policy\nand Terms of Service")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 16)

                    Spacer(minLength: 40)

                    // MARK: - Back to Login Link

                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))

                        Button(action: { dismiss() }) {
                            Text("Log In")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Handle Sign Up

    private func handleSignUp() {

        authManager.errorMessage = nil
        successMessage = nil

        let cleanEmail = email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !cleanEmail.isEmpty else {
            authManager.errorMessage = "Please enter your email address."
            return
        }

        guard !password.isEmpty else {
            authManager.errorMessage = "Please enter a password."
            return
        }

        guard password.count >= 6 else {
            authManager.errorMessage = "Password must be at least 6 characters."
            return
        }

        guard password == confirmPassword else {
            authManager.errorMessage = "Passwords do not match."
            return
        }

        isSubmitting = true

        Task {

            do {

                try await authManager.signUp(
                    email: cleanEmail,
                    password: password
                )

                // Account created successfully!
                successMessage =
                    "✅ Account created! Check \(cleanEmail) for a verification email. Click the link to verify your account."

                // Clear password fields for security
                password = ""
                confirmPassword = ""
                showPassword = false
                showConfirmPassword = false

            } catch {

                // AuthManager already handles error messages

            }

            isSubmitting = false
        }
    }
}
