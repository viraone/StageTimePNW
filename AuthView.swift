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

            // Background: Beautiful blue/purple mountain aesthetic
            ZStack {
                // Base gradient - Deep blue to purple
                LinearGradient(
                    colors: [
                        Color(red: 0.35, green: 0.45, blue: 0.65), // Soft blue
                        Color(red: 0.25, green: 0.35, blue: 0.55), // Medium blue
                        Color(red: 0.15, green: 0.20, blue: 0.40), // Deep navy
                        Color(red: 0.12, green: 0.15, blue: 0.30)  // Dark navy/purple
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Add depth with radial highlights
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.08),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 50,
                    endRadius: 500
                )
                
                // Subtle overlay for texture
                Color.black.opacity(0.15)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                
                // MARK: - Back Button
                
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 17, weight: .regular))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                ScrollView(showsIndicators: false) {

                    VStack(spacing: 0) {

                        Spacer(minLength: 20)

                        // MARK: - Hero Section

                        VStack(spacing: 16) {
                            
                            Text("STAGE TIME PNW")
                                .font(.system(size: 22, weight: .thin, design: .default))
                                .foregroundColor(.white)
                                .tracking(4)
                        }
                        .padding(.bottom, 40)

                    // MARK: - Form Content

                    VStack(spacing: 24) {
                        
                        // Title
                        Text("Create your account")
                            .font(.system(size: 28, weight: .thin))
                            .foregroundColor(.white)

                        // MARK: - Input Fields

                        VStack(spacing: 14) {

                            // Email Field with Icon
                            HStack(spacing: 12) {
                                Image(systemName: "envelope")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(width: 20)
                                
                                ZStack(alignment: .leading) {
                                    if email.isEmpty {
                                        Text("Email address")
                                            .foregroundColor(.white.opacity(0.5))
                                            .font(.system(size: 15))
                                    }
                                    TextField("", text: $email)
                                        .font(.system(size: 15))
                                        .foregroundColor(.white)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .textContentType(.emailAddress)
                                        .accessibilityIdentifier("signup_email_input")
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )

                            // Password Field with Icon
                            HStack(spacing: 12) {
                                Image(systemName: "lock")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(width: 20)
                                
                                ZStack(alignment: .leading) {
                                    if password.isEmpty && !showPassword {
                                        Text("Password (min. 6 characters)")
                                            .foregroundColor(.white.opacity(0.5))
                                            .font(.system(size: 15))
                                    }
                                    
                                    TextField("", text: $password)
                                        .textContentType(.newPassword)
                                        .accessibilityIdentifier("signup_password_input")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white)
                                        .autocapitalization(.none)
                                }
                                
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.fill" : "eye.slash.fill")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )

                            // Confirm Password Field with Icon
                            HStack(spacing: 12) {
                                Image(systemName: "lock.shield")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(width: 20)
                                
                                ZStack(alignment: .leading) {
                                    if confirmPassword.isEmpty && !showConfirmPassword {
                                        Text("Confirm password")
                                            .foregroundColor(.white.opacity(0.5))
                                            .font(.system(size: 15))
                                    }
                                    
                                    TextField("", text: $confirmPassword)
                                        .textContentType(.newPassword)
                                        .accessibilityIdentifier("signup_confirm_password_input")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white)
                                        .autocapitalization(.none)
                                }
                                
                                Button(action: { showConfirmPassword.toggle() }) {
                                    Image(systemName: showConfirmPassword ? "eye.fill" : "eye.slash.fill")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }

                        // MARK: - Success Message

                        if let successMessage {

                            VStack(spacing: 10) {

                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color(red: 0.50, green: 0.60, blue: 0.80))

                                Text(successMessage)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.95))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(3)
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.50, green: 0.60, blue: 0.80).opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(red: 0.50, green: 0.60, blue: 0.80).opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .padding(.top, 8)
                            .accessibilityIdentifier("signup_success_message")
                        }

                        // MARK: - Error Message Display

                        if let error = authManager.errorMessage {

                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.red.opacity(0.9))
                                
                                Text(error)
                                    .font(.system(size: 13))
                                    .foregroundColor(.red.opacity(0.95))
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .padding(.top, 8)
                            .accessibilityIdentifier("signup_error_message")
                        }

                        // MARK: - Create Account Button

                        Button(action: handleSignUp) {

                            if isSubmitting {

                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)

                            } else {

                                HStack(spacing: 8) {
                                    Text("Create Account")
                                        .font(.system(size: 17, weight: .medium))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                            }
                        }
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.50, green: 0.60, blue: 0.80), // Soft blue
                                    Color(red: 0.40, green: 0.50, blue: 0.70)  // Medium blue
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: Color(red: 0.40, green: 0.50, blue: 0.70).opacity(0.4), radius: 10, x: 0, y: 5)
                        .padding(.top, 8)
                        .disabled(isSubmitting)
                        .accessibilityIdentifier("signup_submit_button")

                        // Privacy Policy Text
                        HStack(spacing: 4) {
                            Image(systemName: "lock.shield")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.4))
                            
                            Text("By creating an account, you accept our Privacy Policy and Terms of Service")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .multilineTextAlignment(.center)
                        .padding(.top, 12)
                        
                    }
                    .padding(.horizontal, 32)

                    Spacer(minLength: 30)

                    // MARK: - Back to Login Link

                    HStack(spacing: 6) {
                        Text("Already have an account?")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.7))

                        Button(action: { dismiss() }) {
                            Text("Log In")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .underline()
                        }
                    }
                    .padding(.bottom, 50)
                }
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
