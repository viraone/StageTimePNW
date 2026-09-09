import Foundation
@testable import StageTimePNW

/// Scriptable auth backend. Each call records itself for assertions.
final class FakeAuthRepository: AuthRepository, @unchecked Sendable {
    enum Call: Equatable {
        case restoreSession
        case signUp(email: String, password: String)
        case signIn(email: String, password: String)
        case signOut
        case callback(URL)
    }

    var restoredUser: AuthUser?
    var signUpResult: Result<Void, Error> = .success(())
    var signInResult: Result<AuthUser, Error>
    var signOutResult: Result<Void, Error> = .success(())
    var callbackResult: Result<AuthUser, Error>
    private(set) var calls: [Call] = []

    init(
        signInResult: Result<AuthUser, Error> = .success(.confirmed),
        callbackResult: Result<AuthUser, Error> = .success(.confirmed)
    ) {
        self.signInResult = signInResult
        self.callbackResult = callbackResult
    }

    func restoreSession() async -> AuthUser? {
        calls.append(.restoreSession)
        return restoredUser
    }

    func signUp(email: String, password: String) async throws {
        calls.append(.signUp(email: email, password: password))
        try signUpResult.get()
    }

    func signIn(email: String, password: String) async throws -> AuthUser {
        calls.append(.signIn(email: email, password: password))
        return try signInResult.get()
    }

    func signOut() async throws {
        calls.append(.signOut)
        try signOutResult.get()
    }

    func session(fromCallback url: URL) async throws -> AuthUser {
        calls.append(.callback(url))
        return try callbackResult.get()
    }
}

extension AuthUser {
    static let confirmed = AuthUser(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        email: "confirmed@stagetimepnw.test",
        isEmailConfirmed: true
    )
    static let unconfirmed = AuthUser(
        id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        email: "pending@stagetimepnw.test",
        isEmailConfirmed: false
    )
}
