import XCTest
@testable import StageTimePNW

@MainActor
final class OpenMicViewModelTests: XCTestCase {

    private func makeSUT(
        mics: FakeOpenMicRepository = FakeOpenMicRepository(),
        signups: FakeSignupRepository = FakeSignupRepository()
    ) -> OpenMicViewModel {
        OpenMicViewModel(micRepository: mics, signupRepository: signups, toastDuration: .zero, loadOnInit: false)
    }

    // MARK: Directory

    func testFetchMicsSurfacesErrorAndClearsLoading() async {
        let repo = FakeOpenMicRepository(result: .failure(RepositoryError.badStatus(503)))
        let sut = makeSUT(mics: repo)

        await sut.fetchMics()

        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.loadError, "Server responded with status 503.")
        XCTAssertTrue(sut.allMics.isEmpty)
    }

    func testFetchMicsClearsPreviousError() async {
        let repo = FakeOpenMicRepository(result: .failure(RepositoryError.badStatus(500)))
        let sut = makeSUT(mics: repo)
        await sut.fetchMics()
        repo.result = .success([])

        await sut.fetchMics()

        XCTAssertNil(sut.loadError)
        XCTAssertEqual(repo.fetchCount, 2)
    }

    // MARK: Signup lookup

    func testCheckActiveSignupWithoutUserIsFalseAndSkipsBackend() async {
        let signups = FakeSignupRepository()
        let sut = makeSUT(signups: signups)

        await sut.checkActiveSignup(for: nil)

        XCTAssertFalse(sut.hasActiveSignup)
        XCTAssertTrue(signups.lookups.isEmpty)
    }

    func testCheckActiveSignupQueriesByUserID() async {
        let signups = FakeSignupRepository()
        signups.hasActiveResult = .success(true)
        let sut = makeSUT(signups: signups)

        await sut.checkActiveSignup(for: .confirmed)

        XCTAssertTrue(sut.hasActiveSignup)
        XCTAssertEqual(signups.lookups, [AuthUser.confirmed.id])
        XCTAssertFalse(sut.isCheckingSignup)
    }

    func testCheckActiveSignupFailureNeverAssumesSubmitted() async {
        let signups = FakeSignupRepository()
        signups.hasActiveResult = .failure(StubError(message: "offline"))
        let sut = makeSUT(signups: signups)

        await sut.checkActiveSignup(for: .confirmed)

        XCTAssertFalse(sut.hasActiveSignup)
    }

    // MARK: Signup submit

    func testSubmitSignupBuildsVerifiedRequestFromUser() async {
        let signups = FakeSignupRepository()
        let sut = makeSUT(signups: signups)

        let ok = await sut.submitSignup(
            for: .confirmed, stageName: "  Vira  ", instagram: "@vira",
            performedBefore: true, noShowAgreement: true, guaranteeAgreement: true
        )

        XCTAssertTrue(ok)
        XCTAssertTrue(sut.hasActiveSignup)
        XCTAssertNil(sut.signupError)
        XCTAssertEqual(signups.submitted, [
            SignupRequest(
                name: "Vira", email: "confirmed@stagetimepnw.test", instagram: "@vira",
                performedBefore: true, noShowAgreement: true, guaranteeAgreement: true,
                isVerified: true, authUserID: AuthUser.confirmed.id
            ),
        ])
    }

    func testSubmitSignupWithoutUserFails() async {
        let signups = FakeSignupRepository()
        let sut = makeSUT(signups: signups)

        let ok = await sut.submitSignup(
            for: nil, stageName: "x", instagram: "",
            performedBefore: false, noShowAgreement: true, guaranteeAgreement: true
        )

        XCTAssertFalse(ok)
        XCTAssertEqual(sut.signupError, RepositoryError.notAuthenticated.errorDescription)
        XCTAssertTrue(signups.submitted.isEmpty)
    }

    func testSubmitSignupBackendFailureSurfacesError() async {
        let signups = FakeSignupRepository()
        signups.submitResult = .failure(StubError(message: "duplicate key"))
        let sut = makeSUT(signups: signups)

        let ok = await sut.submitSignup(
            for: .confirmed, stageName: "x", instagram: "",
            performedBefore: false, noShowAgreement: true, guaranteeAgreement: true
        )

        XCTAssertFalse(ok)
        XCTAssertFalse(sut.hasActiveSignup)
        XCTAssertEqual(sut.signupError, "duplicate key")
    }

    func testSignupRequestEncodesSnakeCaseColumns() throws {
        let request = SignupRequest(
            name: "n", email: "e", instagram: "i", performedBefore: true,
            noShowAgreement: true, guaranteeAgreement: false, isVerified: true,
            authUserID: AuthUser.confirmed.id
        )
        let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any]
        XCTAssertEqual(Set(json?.keys.map { $0 } ?? []), [
            "name", "email", "instagram", "performed_before", "no_show_agreement",
            "guarantee_agreement", "is_verified", "auth_user_id",
        ])
    }
}
