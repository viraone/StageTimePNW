import SwiftUI

struct AuthView: View {

    @EnvironmentObject var authManager: AuthManager

    @State private var isSignUp: Bool = false
    @State private var userName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""

    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false

    @State private var rememberMe: Bool = true
    @State private var isSubmitting: Bool = false

    @State private var localError: String? = nil

    // NEW:
    // Used after a successful Sign Up.
    // This keeps the user on the Auth screen and tells them
    // to verify their email before logging in.
    @State private var successMessage: String? = nil

    var body: some View {

        ZStack {

            // Background: Deep dark atmospheric gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.10, green: 0.12, blue: 0.15),
                    Color(red: 0.05, green: 0.05, blue: 0.07)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {

                VStack(spacing: 22) {

                    Spacer(minLength: 35)

                    // MARK: - STAGE TIME PNW BRANDING HEADER

                    VStack(spacing: 6) {

                        Text("STAGE TIME PNW")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.white)
                            .tracking(2)

                        Text("Pacific Northwest Comedy Directory & Signups")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                    }

                    // MARK: - Subtitle

                    Text(
                        isSignUp
                        ? "Sign up to request your open mic spot"
                        : "Log in to request your open mic spot"
                    )
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 4)

                    // MARK: - Input Form

                    VStack(alignment: .leading, spacing: 14) {

                        // 1. User Name - Sign Up only

                        if isSignUp {

                            VStack(alignment: .leading, spacing: 5) {

                                Text("User Name")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))

                                CustomInputField(
                                    placeholder: "Stage name / Full name",
                                    text: $userName
                                )
                            }
                            .transition(
                                .opacity.combined(
                                    with: .move(edge: .top)
                                )
                            )
                        }

                        // 2. Email Address

                        VStack(alignment: .leading, spacing: 5) {

                            Text("Email")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))

                            CustomInputField(
                                placeholder: "Email address",
                                text: $email,
                                keyboardType: .emailAddress,
                                autocapitalize: false
                            )
                        }

                        // 3. Password

                        VStack(alignment: .leading, spacing: 5) {

                            Text("Password")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))

                            HStack {

                                if showPassword {

                                    TextField(
                                        "Password",
                                        text: $password
                                    )
                                    .foregroundColor(.black)
                                    .autocapitalization(.none)

                                } else {

                                    SecureField(
                                        "Password",
                                        text: $password
                                    )
                                    .foregroundColor(.black)
                                    .autocapitalization(.none)
                                }

                                Button(
                                    action: {
                                        showPassword.toggle()
                                    }
                                ) {

                                    Image(
                                        systemName:
                                            showPassword
                                            ? "eye"
                                            : "eye.slash"
                                    )
                                    .foregroundColor(.gray)
                                    .font(.system(size: 16))
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 13)
                            .background(
                                Color(
                                    red: 0.85,
                                    green: 0.86,
                                    blue: 0.89
                                )
                            )
                            .cornerRadius(8)
                        }

                        // 4. Confirm Password - Sign Up only

                        if isSignUp {

                            VStack(alignment: .leading, spacing: 5) {

                                Text("Confirm password")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))

                                HStack {

                                    if showConfirmPassword {

                                        TextField(
                                            "Confirm password",
                                            text: $confirmPassword
                                        )
                                        .foregroundColor(.black)
                                        .autocapitalization(.none)

                                    } else {

                                        SecureField(
                                            "Confirm password",
                                            text: $confirmPassword
                                        )
                                        .foregroundColor(.black)
                                        .autocapitalization(.none)
                                    }

                                    Button(
                                        action: {
                                            showConfirmPassword.toggle()
                                        }
                                    ) {

                                        Image(
                                            systemName:
                                                showConfirmPassword
                                                ? "eye"
                                                : "eye.slash"
                                        )
                                        .foregroundColor(.gray)
                                        .font(.system(size: 16))
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 13)
                                .background(
                                    Color(
                                        red: 0.85,
                                        green: 0.86,
                                        blue: 0.89
                                    )
                                )
                                .cornerRadius(8)
                            }
                            .transition(
                                .opacity.combined(
                                    with: .move(edge: .top)
                                )
                            )
                        }

                        // 5. Remember Me & Forgot Password - Login only

                        if !isSignUp {

                            HStack {

                                Toggle(
                                    isOn: $rememberMe
                                ) {

                                    Text("Remember me")
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray)
                                }
                                .toggleStyle(
                                    SmallSwitchToggleStyle()
                                )

                                Spacer()

                                Button(action: {}) {

                                    Text("Forgot password?")
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.top, 2)
                        }
                    }
                    .padding(.horizontal, 28)

                    // MARK: - Success Message

                    if let successMessage {

                        VStack(spacing: 5) {

                            Image(systemName: "envelope.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(
                                    Color(
                                        red: 0.05,
                                        green: 0.82,
                                        blue: 0.45
                                    )
                                )

                            Text(successMessage)
                                .font(
                                    .system(
                                        size: 14,
                                        weight: .semibold
                                    )
                                )
                                .foregroundColor(
                                    Color(
                                        red: 0.05,
                                        green: 0.82,
                                        blue: 0.45
                                    )
                                )
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 28)
                    }

                    // MARK: - Error Message Display

                    if let error = localError ?? authManager.errorMessage {

                        Text(error)
                            .font(.caption)
                            .foregroundColor(.pnwRedText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                    }

                    // MARK: - Main Action Button

                    Button(action: handleAuth) {

                        if isSubmitting {

                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)

                        } else {

                            Text(
                                isSignUp
                                ? "Sign Up"
                                : "Log In"
                            )
                            .font(
                                .system(
                                    size: 16,
                                    weight: .bold
                                )
                            )
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Color(
                                    red: 0.05,
                                    green: 0.82,
                                    blue: 0.45
                                )
                            )
                            .cornerRadius(8)
                            .shadow(
                                color:
                                    Color(
                                        red: 0.05,
                                        green: 0.82,
                                        blue: 0.45
                                    )
                                    .opacity(0.3),
                                radius: 8,
                                y: 4
                            )
                        }
                    }
                    .disabled(isSubmitting)
                    .padding(.horizontal, 28)
                    .padding(.top, 4)

                    // MARK: - Social Login Divider

                    HStack(spacing: 12) {

                        Rectangle()
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 1)

                        Text(
                            isSignUp
                            ? "Or sign up with"
                            : "Or log in with"
                        )
                        .font(.system(size: 12))
                        .foregroundColor(.gray)

                        Rectangle()
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 6)

                    // MARK: - Social Login Buttons

                    HStack(spacing: 14) {

                        SocialLoginButton(
                            iconName: "g.circle.fill",
                            label: "Google"
                        )

                        SocialLoginButton(
                            iconName: "applelogo",
                            label: "Apple"
                        )

                        SocialLoginButton(
                            iconName: "f.circle.fill",
                            label: "Facebook"
                        )
                    }
                    .padding(.horizontal, 28)

                    Spacer(minLength: 20)

                    // MARK: - Bottom Login / Sign Up Toggle

                    Button(
                        action: {

                            withAnimation(
                                .easeInOut(duration: 0.25)
                            ) {

                                isSignUp.toggle()

                                localError = nil
                                authManager.errorMessage = nil

                                // Clear previous success message
                                // when manually switching modes.
                                successMessage = nil

                                password = ""
                                confirmPassword = ""
                            }
                        }
                    ) {

                        HStack(spacing: 6) {

                            Text(
                                isSignUp
                                ? "Already have an account?"
                                : "Don't have an account?"
                            )
                            .font(
                                .system(
                                    size: 16,
                                    weight: .medium
                                )
                            )
                            .foregroundColor(.white)

                            Text(
                                isSignUp
                                ? "Log In"
                                : "Sign Up"
                            )
                            .font(
                                .system(
                                    size: 16,
                                    weight: .black
                                )
                            )
                            .foregroundColor(
                                Color(
                                    red: 0.05,
                                    green: 0.82,
                                    blue: 0.45
                                )
                            )
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(
                            Color.white.opacity(0.08)
                        )
                        .cornerRadius(24)
                    }
                    .padding(.bottom, 25)
                }
            }
        }
    }

    // MARK: - Handle Login / Sign Up

    private func handleAuth() {

        localError = nil
        authManager.errorMessage = nil

        // Do not immediately clear the verification message
        // on Login. This allows the user to still see the
        // reminder after returning from Yahoo.

        let cleanEmail = email
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .lowercased()

        guard !cleanEmail.isEmpty else {

            localError = "Please enter an email address."
            return
        }

        guard !password.isEmpty else {

            localError = "Please enter a password."
            return
        }

        if isSignUp {

            guard !userName
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty else {

                localError = "Please enter your name."
                return
            }

            guard password == confirmPassword else {

                localError = "Passwords do not match."
                return
            }

            guard password.count >= 6 else {

                localError =
                    "Password must be at least 6 characters."

                return
            }
        }

        isSubmitting = true

        Task {

            do {

                if isSignUp {

                    try await authManager.signUp(
                        email: cleanEmail,
                        password: password
                    )

                    // SIGN UP SUCCESSFUL
                    //
                    // The account now exists in Supabase,
                    // but we DO NOT send the user into Home.
                    //
                    // They must verify their email first.

                    successMessage =
                        "Check \(cleanEmail) for a verification link before logging in."

                    // Keep their email filled in.
                    email = cleanEmail

                    // Clear password fields for security.
                    password = ""
                    confirmPassword = ""

                    // Hide password visibility.
                    showPassword = false
                    showConfirmPassword = false

                    // Switch the UI back to Login mode.
                    //
                    // The success message remains visible,
                    // telling them to verify their email.
                    withAnimation(
                        .easeInOut(duration: 0.25)
                    ) {

                        isSignUp = false
                    }

                } else {

                    try await authManager.signIn(
                        email: cleanEmail,
                        password: password
                    )

                    // If login succeeds, StageTimePNWApp.swift
                    // will automatically switch to ContentView
                    // because isAuthenticated becomes true.
                }

            } catch {

                // AuthManager already places Supabase errors
                // inside authManager.errorMessage.

                if authManager.errorMessage == nil {

                    authManager.errorMessage =
                        error.localizedDescription
                }
            }

            isSubmitting = false
        }
    }
}

// MARK: - Reusable Light Grey Input Field

struct CustomInputField: View {

    let placeholder: String

    @Binding var text: String

    var keyboardType: UIKeyboardType = .default

    var autocapitalize: Bool = true

    var body: some View {

        TextField(
            placeholder,
            text: $text
        )
        .font(.system(size: 15))
        .foregroundColor(.black)
        .keyboardType(keyboardType)
        .autocapitalization(
            autocapitalize
            ? .words
            : .none
        )
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(
            Color(
                red: 0.85,
                green: 0.86,
                blue: 0.89
            )
        )
        .cornerRadius(8)
    }
}

// MARK: - Reusable Social Button

struct SocialLoginButton: View {

    let iconName: String

    let label: String

    var body: some View {

        Button(
            action: {

                // Social Auth Hook
            }
        ) {

            HStack {

                Image(systemName: iconName)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                Color.white.opacity(0.12)
            )
            .cornerRadius(8)
            .overlay(

                RoundedRectangle(
                    cornerRadius: 8
                )
                .stroke(
                    Color.white.opacity(0.08),
                    lineWidth: 1
                )
            )
        }
    }
}

// MARK: - Compact Toggle Style

struct SmallSwitchToggleStyle: ToggleStyle {

    func makeBody(
        configuration: Configuration
    ) -> some View {

        HStack {

            Toggle(
                "",
                isOn: configuration.$isOn
            )
            .labelsHidden()
            .scaleEffect(0.7)

            configuration.label
        }
    }
}
