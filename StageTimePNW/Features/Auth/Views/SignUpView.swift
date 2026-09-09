import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @FocusState private var focusedField: AuthValidation.Field?

    var body: some View {
        ZStack {
            AuthBackground()

            VStack(spacing: 0) {
                backButton
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        brand
                            .padding(.top, 20)
                            .padding(.bottom, 40)

                        form
                            .padding(.horizontal, 32)

                        signInPrompt
                            .padding(.top, 30)
                            .padding(.bottom, 50)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Sections

    private var backButton: some View {
        HStack {
            Button { dismiss() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
                    Text("Back").font(.system(size: 17))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .accessibilityIdentifier("signup_back_button")
            Spacer()
        }
    }

    private var brand: some View {
        Text("STAGE TIME PNW")
            .font(.system(size: 22, weight: .thin))
            .foregroundColor(.white)
            .tracking(4)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("signup_brand_title")
    }

    private var form: some View {
        VStack(spacing: 24) {
            Text("Create your account")
                .font(.system(size: 28, weight: .thin))
                .foregroundColor(.white)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("signup_header_title")

            VStack(spacing: 14) {
                AuthTextField(
                    systemImage: "envelope",
                    placeholder: String(localized: "Email address"),
                    kind: .email,
                    accessibilityID: "signup_email_input",
                    text: $email,
                    submitLabel: .next,
                    onSubmit: { focusedField = .password }
                )
                .focused($focusedField, equals: .email)

                AuthTextField(
                    systemImage: "lock",
                    placeholder: String(localized: "Password (min. \(AuthValidation.minimumPasswordLength) characters)"),
                    kind: .password(contentType: .newPassword),
                    accessibilityID: "signup_password_input",
                    text: $password,
                    submitLabel: .next,
                    onSubmit: { focusedField = .confirmPassword }
                )
                .focused($focusedField, equals: .password)

                AuthTextField(
                    systemImage: "lock.shield",
                    placeholder: String(localized: "Confirm password"),
                    kind: .password(contentType: .newPassword),
                    accessibilityID: "signup_confirm_password_input",
                    text: $confirmPassword,
                    submitLabel: .join,
                    onSubmit: submit
                )
                .focused($focusedField, equals: .confirmPassword)
            }

            if let successMessage {
                AuthStatusBanner(style: .success, message: successMessage, accessibilityID: "signup_success_message")
            }

            if let errorMessage {
                AuthStatusBanner(style: .error, message: errorMessage, accessibilityID: "signup_error_message")
            }

            AuthPrimaryButton(
                title: String(localized: "Create Account"),
                isBusy: isSubmitting,
                accessibilityID: "signup_submit_button",
                action: submit
            )
            .padding(.top, 8)

            LegalFooter(text: String(localized: "By creating an account, you accept our Privacy Policy and Terms of Service"))
                .padding(.top, 12)
        }
    }

    private var signInPrompt: some View {
        HStack(spacing: 6) {
            Text("Already have an account?")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.7))

            Button { dismiss() } label: {
                Text("Log In")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .underline()
            }
            .accessibilityIdentifier("signup_to_signin_link")
        }
    }

    // MARK: - Actions

    private func submit() {
        errorMessage = nil
        successMessage = nil

        if let failure = AuthValidation.validateSignUp(
            email: email, password: password, confirmPassword: confirmPassword
        ) {
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
                try await authManager.signUp(email: cleanEmail, password: password)
                successMessage = String(
                    localized: "Account created! Check \(cleanEmail) for a verification email. Click the link to verify your account."
                )
                password = ""
                confirmPassword = ""
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
