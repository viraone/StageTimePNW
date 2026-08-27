//
//  OpenMicService.swift
//  StageTimePNW
//

import Foundation

/// Loads open mic data from the same JSON that powers stagetimepnw.com
/// (data/open-mics.json in the slotted-killer project).
enum OpenMicService {
    static let openMicsURL = URL(string: "https://stagetimepnw.com/data/open-mics.json")!

    static func fetchOpenMics() async throws -> [OpenMic] {
        var request = URLRequest(url: openMicsURL)
        request.cachePolicy = .reloadRevalidatingCacheData
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([OpenMic].self, from: data)
    }
}
