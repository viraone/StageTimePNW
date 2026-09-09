import XCTest
@testable import StageTimePNW

@MainActor
final class AuthManagerTests: XCTestCase {

    private func makeSUT(_ repo: FakeAuthRepository = FakeAuthRepository()) -> (AuthManager, FakeAuthRepository) {
        (AuthManager(repository: repo, restoreOnInit: false), repo)
    }

    // MARK: Session restore

    func testCheckSessionAuthenticatesConfirmedUser() async {
        let (sut, repo) = makeSUT()
        repo.restoredUser = .confirmed

        await sut.checkSession()

        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(sut.currentUser, .confirmed)
        XCTAssertFalse(sut.isLoading)
    }

    func testCheckSessionRejectsUnconfirmedUser() async {
        let (sut, repo) = makeSUT()
        repo.restoredUser = .unconfirmed

        await sut.checkSession()

        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUser)
    }

    func testCheckSessionWithNoSessionIsSignedOut() async {
        let (sut, _) = makeSUT()
        await sut.checkSession()
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: Sign up

    func testSignUpForwardsCredentialsAndStaysSignedOut() async throws {
        let (sut, repo) = makeSUT()

        try await sut.signUp(email: "new@stagetimepnw.test", password: "Passw0rd!")

        XCTAssertEqual(repo.calls, [.signUp(email: "new@stagetimepnw.test", password: "Passw0rd!")])
        XCTAssertFalse(sut.isAuthenticated, "Email must be verified before first sign-in")
    }

    func testSignUpPropagatesBackendError() async {
        let (sut, repo) = makeSUT()
        repo.signUpResult = .failure(AuthError.backend(message: "Error sending confirmation email"))

        do {
            try await sut.signUp(email: "x@y.z", password: "Passw0rd!")
            XCTFail("expected throw")
        } catch let error as AuthError {
            XCTAssertEqual(error, .backend(message: "Error sending confirmation email"))
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

    // MARK: Sign in

    func testSignInWithConfirmedUserAuthenticates() async throws {
        let (sut, _) = makeSUT(FakeAuthRepository(signInResult: .success(.confirmed)))

        try await sut.signIn(email: "confirmed@stagetimepnw.test", password: "pw")

        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(sut.currentUser, .confirmed)
    }

    func testSignInWithUnconfirmedUserThrowsAndStaysSignedOut() async {
        let (sut, _) = makeSUT(FakeAuthRepository(signInResult: .success(.unconfirmed)))

        do {
            try await sut.signIn(email: "pending@stagetimepnw.test", password: "pw")
            XCTFail("expected throw")
        } catch let error as AuthError {
            XCTAssertEqual(error, .emailNotConfirmed)
        } catch {
            XCTFail("unexpected error \(error)")
        }
        XCTAssertFalse(sut.isAuthenticated)
    }

    // MARK: Sign out

    func testSignOutClearsStateEvenWhenBackendFails() async {
        let (sut, repo) = makeSUT()
        repo.restoredUser = .confirmed
        await sut.checkSession()
        repo.signOutResult = .failure(StubError(message: "offline"))

        await sut.signOut()

        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUser)
    }

    // MARK: Deep links

    func testVerificationCallbackRecognition() {
        XCTAssertTrue(AuthManager.isVerificationCallback(URL(string: "stagetimepnw://auth/callback?code=abc")!))
        XCTAssertFalse(AuthManager.isVerificationCallback(URL(string: "https://auth/callback")!))
        XCTAssertFalse(AuthManager.isVerificationCallback(URL(string: "stagetimepnw://other/callback")!))
    }

    func testDeepLinkWithWrongSchemeSetsErrorWithoutCallingBackend() async {
        let (sut, repo) = makeSUT()

        await sut.handleDeepLink(url: URL(string: "https://evil.example/auth/callback")!)

        XCTAssertEqual(sut.errorMessage, AuthError.invalidDeepLink.errorDescription)
        XCTAssertTrue(repo.calls.isEmpty)
    }

    func testDeepLinkWithErrorQuerySetsErrorWithoutCallingBackend() async {
        let (sut, repo) = makeSUT()

        await sut.handleDeepLink(url: URL(string: "stagetimepnw://auth/callback?error=access_denied&error_code=otp_expired")!)

        XCTAssertEqual(sut.errorMessage, AuthError.deepLinkRejected.errorDescription)
        XCTAssertTrue(repo.calls.isEmpty)
    }

    func testValidDeepLinkAuthenticates() async {
        let (sut, _) = makeSUT(FakeAuthRepository(callbackResult: .success(.confirmed)))

        await sut.handleDeepLink(url: URL(string: "stagetimepnw://auth/callback?code=abc")!)

        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertNil(sut.errorMessage)
    }
}
