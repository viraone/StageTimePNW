import Foundation

/// Pure, testable input rules shared by sign-in and sign-up.
enum AuthValidation {
    static let minimumPasswordLength = 6

    enum Field { case email, password, confirmPassword }

    struct Failure: Equatable, LocalizedError {
        let field: Field
        let message: String
        var errorDescription: String? { message }
    }

    static func normalizeEmail(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func validateSignIn(email: String, password: String) -> Failure? {
        if normalizeEmail(email).isEmpty {
            return Failure(field: .email, message: String(localized: "Please enter your email address."))
        }
        if password.isEmpty {
            return Failure(field: .password, message: String(localized: "Please enter your password."))
        }
        return nil
    }

    static func validateSignUp(email: String, password: String, confirmPassword: String) -> Failure? {
        if normalizeEmail(email).isEmpty {
            return Failure(field: .email, message: String(localized: "Please enter your email address."))
        }
        if password.isEmpty {
            return Failure(field: .password, message: String(localized: "Please enter a password."))
        }
        if password.count < minimumPasswordLength {
            return Failure(field: .password, message: String(localized: "Password must be at least 6 characters."))
        }
        if password != confirmPassword {
            return Failure(field: .confirmPassword, message: String(localized: "Passwords do not match."))
        }
        return nil
    }
}
