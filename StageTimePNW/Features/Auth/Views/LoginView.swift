import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authManager: AuthManager

    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: AuthValidation.Field?

    var body: some View {
        ZStack {
            AuthBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    brand
                        .padding(.top, 50)
                        .padding(.bottom, 40)

                    formCard
                        .padding(.horizontal, 24)

                    divider
                        .padding(.horizontal, 32)
                        .padding(.top, 24)

                    socialButtons
                        .padding(.horizontal, 32)
                        .padding(.top, 16)

                    signUpPrompt
                        .padding(.top, 30)
                        .padding(.bottom, 50)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationBarHidden(true)
        .onAppear(perform: loadSavedCredentials)
    }

    // MARK: - Sections

    private var brand: some View {
        Text("STAGE TIME PNW")
            .font(.system(size: 22, weight: .thin))
            .foregroundColor(.white)
            .tracking(4)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("signin_brand_title")
    }

    private var formCard: some View {
        VStack(spacing: 24) {
            Text("Sign in")
                .font(.system(size: 28, weight: .thin))
                .foregroundColor(.white)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("signin_header_title")

            VStack(spacing: 14) {
                AuthTextField(
                    systemImage: "envelope",
                    placeholder: String(localized: "Email address"),
                    kind: .email,
                    accessibilityID: "signin_email_input",
                    text: $email,
                    submitLabel: .next,
                    onSubmit: { focusedField = .password }
                )
                .focused($focusedField, equals: .email)

                AuthTextField(
                    systemImage: "lock",
                    placeholder: String(localized: "Password"),
                    kind: .password(contentType: .password),
                    accessibilityID: "signin_password_input",
                    text: $password,
                    submitLabel: .go,
                    onSubmit: submit
                )
                .focused($focusedField, equals: .password)

                HStack {
                    Toggle(isOn: $rememberMe) {
                        Text("Remember me")
                            .font(.system(size: 13, weight: .light))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .toggleStyle(CheckboxToggleStyle())
                    .accessibilityIdentifier("signin_remember_me_toggle")

                    Spacer()

                    Button {
                        // TODO: password reset flow
                    } label: {
                        Text("Forgot password?")
                            .font(.system(size: 13, weight: .light))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .accessibilityIdentifier("signin_forgot_password_button")
                }
                .padding(.top, 8)
            }

            if let errorMessage {
                AuthStatusBanner(style: .error, message: errorMessage, accessibilityID: "signin_error_message")
            }

            AuthPrimaryButton(
                title: String(localized: "Sign in"),
                isBusy: isSubmitting,
                accessibilityID: "signin_submit_button",
                action: submit
            )
            .padding(.top, 8)

            LegalFooter(text: String(localized: "By signing in, you accept our Privacy Policy and Terms of Service"))
                .padding(.top, 12)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: AuthTheme.Metrics.cardCornerRadius)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: AuthTheme.Metrics.cardCornerRadius)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var divider: some View {
        HStack(spacing: 16) {
            Rectangle().fill(Color.white.opacity(0.25)).frame(height: 1)
            Text("or")
                .font(.system(size: 13, weight: .light))
                .foregroundColor(.white.opacity(0.6))
            Rectangle().fill(Color.white.opacity(0.25)).frame(height: 1)
        }
        .accessibilityHidden(true)
    }

    private var socialButtons: some View {
        VStack(spacing: 12) {
            SocialSignInButton(title: String(localized: "Continue with Google"), systemImage: "g.circle.fill", accessibilityID: "signin_google_button") {
                // TODO: Google OAuth
            }
            SocialSignInButton(title: String(localized: "Continue with Apple"), systemImage: "apple.logo", accessibilityID: "signin_apple_button") {
                // TODO: Sign in with Apple
            }
        }
    }

    private var signUpPrompt: some View {
        HStack(spacing: 6) {
            Text("Don't have an account?")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.7))

            NavigationLink(destination: SignUpView()) {
                Text("Sign up")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .underline()
            }
            .accessibilityIdentifier("signin_to_signup_link")
        }
    }

    // MARK: - Actions

    private func loadSavedCredentials() {
        guard SavedCredentials.isEnabled else { return }
        rememberMe = true
        if email.isEmpty { email = SavedCredentials.savedEmail }
        if password.isEmpty { password = SavedCredentials.savedPassword }
    }

    private func submit() {
        errorMessage = nil

        if let failure = AuthValidation.validateSignIn(email: email, password: password) {
            errorMessage = failure.message
            focusedField = failure.field
            return
        }

        let cleanEmail = AuthValidation.normalizeEmail(email)
        focusedField = nil
        isSubmitting = true

        Task {
            defer { isSubmitting = false }
            do {
                try await authManager.signIn(email: cleanEmail, password: password)
                if rememberMe {
                    SavedCredentials.save(email: cleanEmail, password: password)
                } else {
                    SavedCredentials.clear()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Local components

private struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack(spacing: 8) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 16))
                    .foregroundColor(configuration.isOn ? AuthTheme.Palette.accent : .white.opacity(0.6))
                configuration.label
            }
        }
        .buttonStyle(.plain)
    }
}

private struct SocialSignInButton: View {
    let title: String
    let systemImage: String
    let accessibilityID: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage).font(.system(size: 18))
                Text(title).font(.system(size: 15, weight: .light))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.08))
            .cornerRadius(AuthTheme.Metrics.fieldCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AuthTheme.Metrics.fieldCornerRadius)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
        .accessibilityIdentifier(accessibilityID)
    }
}

struct LegalFooter: View {
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.shield")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.4))
                .accessibilityHidden(true)
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
        .multilineTextAlignment(.center)
    }
}
