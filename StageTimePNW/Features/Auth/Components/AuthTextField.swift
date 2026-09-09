import SwiftUI

/// Icon + placeholder + input used by every auth form field.
///
/// `isSecure` renders a `SecureField` with an in-field visibility toggle; the
/// toggle swaps to a plain `TextField` only while the user holds it visible.
struct AuthTextField: View {
    enum Kind {
        case email
        /// `.newPassword` on sign-up lets iOS offer its "Use Strong Password?"
        /// sheet; `.password` on sign-in enables keychain autofill.
        case password(contentType: UITextContentType)
    }

    let systemImage: String
    let placeholder: String
    let kind: Kind
    let accessibilityID: String
    @Binding var text: String
    var submitLabel: SubmitLabel = .next
    var onSubmit: () -> Void = {}

    @State private var isRevealed = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: AuthTheme.Metrics.iconColumnWidth)
                .accessibilityHidden(true)

            // The placeholder is passed as the field's `prompt` rather than a
            // conditional overlay: toggling an `if text.isEmpty` sibling changes
            // the view hierarchy on the first keystroke, which re-creates the
            // `SecureField` and drops focus mid-typing.
            input
                .font(.system(size: 15))
                .foregroundColor(.white)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(submitLabel)
                .onSubmit(onSubmit)
                .accessibilityLabel(placeholder)
                .accessibilityIdentifier(accessibilityID)

            if case .password = kind {
                Button {
                    isRevealed.toggle()
                } label: {
                    Image(systemName: isRevealed ? "eye.fill" : "eye.slash.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.5))
                }
                .accessibilityLabel(isRevealed ? "Hide password" : "Show password")
                .accessibilityIdentifier(toggleAccessibilityID)
            }
        }
        .authFieldChrome()
    }

    /// `signin_password_input` -> `signin_password_toggle_button`
    private var toggleAccessibilityID: String {
        accessibilityID.hasSuffix("_input")
            ? String(accessibilityID.dropLast("_input".count)) + "_toggle_button"
            : accessibilityID + "_toggle_button"
    }

    @ViewBuilder
    private var input: some View {
        switch kind {
        case .email:
            TextField("", text: $text, prompt: prompt)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
        case .password(let contentType):
            if isRevealed {
                TextField("", text: $text, prompt: prompt)
                    .textContentType(contentType)
            } else {
                SecureField("", text: $text, prompt: prompt)
                    .textContentType(contentType)
            }
        }
    }

    private var prompt: Text {
        Text(placeholder)
            .foregroundColor(.white.opacity(0.5))
            .font(.system(size: 15))
    }
}
