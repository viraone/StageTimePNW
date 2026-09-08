import XCTest
@testable import StageTimePNW

final class AuthValidationTests: XCTestCase {

    func testNormalizeEmailTrimsAndLowercases() {
        XCTAssertEqual(AuthValidation.normalizeEmail("  Comic@Example.COM \n"), "comic@example.com")
    }

    // MARK: Sign in

    func testSignInRequiresEmail() {
        let failure = AuthValidation.validateSignIn(email: "   ", password: "secret")
        XCTAssertEqual(failure?.field, .email)
    }

    func testSignInRequiresPassword() {
        let failure = AuthValidation.validateSignIn(email: "a@b.co", password: "")
        XCTAssertEqual(failure?.field, .password)
    }

    func testSignInAcceptsValidInput() {
        XCTAssertNil(AuthValidation.validateSignIn(email: "a@b.co", password: "x"))
    }

    // MARK: Sign up

    func testSignUpRequiresEmail() {
        XCTAssertEqual(AuthValidation.validateSignUp(email: "", password: "123456", confirmPassword: "123456")?.field, .email)
    }

    func testSignUpRequiresPassword() {
        XCTAssertEqual(AuthValidation.validateSignUp(email: "a@b.co", password: "", confirmPassword: "")?.field, .password)
    }

    func testSignUpEnforcesMinimumPasswordLength() {
        let failure = AuthValidation.validateSignUp(email: "a@b.co", password: "12345", confirmPassword: "12345")
        XCTAssertEqual(failure?.field, .password)
        XCTAssertEqual(failure?.message, "Password must be at least 6 characters.")
    }

    func testSignUpRequiresMatchingConfirmation() {
        let failure = AuthValidation.validateSignUp(email: "a@b.co", password: "Passw0rd!", confirmPassword: "Passw0rd?")
        XCTAssertEqual(failure?.field, .confirmPassword)
        XCTAssertEqual(failure?.message, "Passwords do not match.")
    }

    func testSignUpAcceptsValidInput() {
        XCTAssertNil(AuthValidation.validateSignUp(email: "a@b.co", password: "Passw0rd!", confirmPassword: "Passw0rd!"))
    }
}
