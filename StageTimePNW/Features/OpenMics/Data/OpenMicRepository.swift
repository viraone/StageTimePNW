import Foundation
import OSLog

protocol OpenMicRepository: Sendable {
    func fetchMics() async throws -> [OpenMic]
}

enum RepositoryError: LocalizedError, Equatable {
    case badStatus(Int)
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .badStatus(let code): return "Server responded with status \(code)."
        case .notAuthenticated: return String(localized: "You need to be signed in to do that.")
        }
    }
}

/// Reads the published open-mic directory from stagetimepnw.com.
struct RemoteOpenMicRepository: OpenMicRepository {
    static let defaultURL = URL(string: "https://stagetimepnw.com/data/open-mics.json")!

    private let url: URL
    private let session: URLSession
    private let decoder = JSONDecoder()

    init(url: URL = RemoteOpenMicRepository.defaultURL, session: URLSession = .shared) {
        self.url = url
        self.session = session
    }

    func fetchMics() async throws -> [OpenMic] {
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw RepositoryError.badStatus(http.statusCode)
        }
        return try decoder.decode([OpenMic].self, from: data)
    }
}
