import Foundation
@testable import StageTimePNW

final class FakeOpenMicRepository: OpenMicRepository, @unchecked Sendable {
    var result: Result<[OpenMic], Error>
    private(set) var fetchCount = 0

    init(result: Result<[OpenMic], Error> = .success([])) {
        self.result = result
    }

    func fetchMics() async throws -> [OpenMic] {
        fetchCount += 1
        return try result.get()
    }
}

final class FakeSignupRepository: SignupRepository, @unchecked Sendable {
    var hasActiveResult: Result<Bool, Error> = .success(false)
    var submitResult: Result<Void, Error> = .success(())
    private(set) var lookups: [UUID] = []
    private(set) var submitted: [SignupRequest] = []

    func hasActiveSignup(userID: UUID) async throws -> Bool {
        lookups.append(userID)
        return try hasActiveResult.get()
    }

    func submit(_ request: SignupRequest) async throws {
        submitted.append(request)
        try submitResult.get()
    }
}

struct StubError: LocalizedError, Equatable {
    let message: String
    var errorDescription: String? { message }
}
