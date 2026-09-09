import Foundation
import Combine
import Vision
import UIKit

/// Looks up the MC for Tacoma Comedy downtown from Bark Entertainment's
/// monthly list page. The schedule is posted as images of a spreadsheet,
/// so we OCR them with Vision and read the MC under the matching date column.
@MainActor
final class BarkMCService: ObservableObject {

    static let shared = BarkMCService()

    static let tacomaDowntownMicID = "tacoma-comedy-downtown-933-market-st-tacoma-wa-98402"

    /// MC name keyed by "yyyy-MM-dd".
    @Published private(set) var mcByDate: [String: String] = [:]

    private var inFlight: Set<String> = []
    private var failed: Set<String> = []

    private static let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    func mc(for date: Date) -> String? {
        mcByDate[Self.dayKeyFormatter.string(from: date)]
    }

    func fetchMC(for date: Date) {
        let key = Self.dayKeyFormatter.string(from: date)
        guard mcByDate[key] == nil, !inFlight.contains(key), !failed.contains(key) else { return }
        inFlight.insert(key)

        Task {
            defer { inFlight.remove(key) }
            do {
                if let name = try await Self.lookupMC(for: date) {
                    mcByDate[key] = name
                } else {
                    failed.insert(key)
                }
            } catch {
                failed.insert(key)
            }
        }
    }

    // MARK: - Pipeline

    private static func lookupMC(for date: Date) async throws -> String? {
        // 1. Open-mic hub page -> find "Downtown <Month> List" link
        let hubHTML = try await fetchString(from: "https://www.barkentertainment.com/open-mic")

        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM"
        let month = monthFormatter.string(from: date)

        guard let listURL = extractListLink(from: hubHTML, month: month) else { return nil }

        // 2. List page -> schedule images
        let listHTML = try await fetchString(from: listURL)
        let imageURLs = extractScheduleImageURLs(from: listHTML)
        guard !imageURLs.isEmpty else { return nil }

        // 3. OCR each image until the date column is found
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"
        let dayNumber = dayFormatter.string(from: date)

        for urlString in imageURLs {
            guard let url = URL(string: urlString) else { continue }
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data), let cgImage = image.cgImage else { continue }
            let observations = try recognizeText(in: cgImage)
            if let mc = findMC(in: observations, month: month, day: dayNumber) {
                return mc
            }
        }
        return nil
    }

    private static func fetchString(from urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone) StageTimePNW", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await URLSession.shared.data(for: request)
        return String(data: data, encoding: .utf8) ?? ""
    }

    /// Finds the href of the anchor whose text contains "Downtown <Month> List".
    static func extractListLink(from html: String, month: String) -> String? {
        let pattern = "<a[^>]+href=\"([^\"]+)\"[^>]*>(?:(?!</a>).)*?Downtown\\s+\(month)\\s+List"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive]),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html) else { return nil }
        return String(html[range])
    }

    /// Collects wixstatic PNG media URLs (the schedule sheets).
    static func extractScheduleImageURLs(from html: String) -> [String] {
        let pattern = "static\\.wixstatic\\.com/media/[a-z0-9_~]+\\.png"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return [] }
        let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))
        var seen = Set<String>()
        var urls: [String] = []
        for m in matches {
            guard let r = Range(m.range, in: html) else { continue }
            let u = "https://" + html[r]
            if seen.insert(u).inserted { urls.append(u) }
        }
        return urls
    }

    // MARK: - OCR

    private struct TextBox {
        let text: String
        let box: CGRect // normalized, origin bottom-left
    }

    private static func recognizeText(in cgImage: CGImage) throws -> [(String, CGRect)] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        let handler = VNImageRequestHandler(cgImage: cgImage)
        try handler.perform([request])
        return (request.results ?? []).compactMap { obs in
            guard let top = obs.topCandidates(1).first else { return nil }
            return (top.string, obs.boundingBox)
        }
    }

    /// Given OCR results, find the "<Month> <day>(st|nd|rd|th)" header and
    /// return the MC name: the first non-weekday text below it in the same column.
    static func findMC(in observations: [(String, CGRect)], month: String, day: String) -> String? {
        let datePattern = "\(month)\\s+\(day)(st|nd|rd|th)?\\b"
        guard let dateRegex = try? NSRegularExpression(pattern: datePattern, options: [.caseInsensitive]) else { return nil }

        guard let dateObs = observations.first(where: { obs in
            dateRegex.firstMatch(in: obs.0, range: NSRange(obs.0.startIndex..., in: obs.0)) != nil
        }) else { return nil }

        let col = dateObs.1
        let weekdays = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]

        // Candidates below the date whose x-center falls within the date column
        let below = observations
            .filter { obs in
                let b = obs.1
                let centerX = b.midX
                return b.midY < col.minY
                    && centerX > col.minX - 0.02
                    && centerX < col.maxX + 0.02
            }
            .sorted { $0.1.midY > $1.1.midY } // top to bottom

        for (text, _) in below {
            let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let lower = clean.lowercased()
            if clean.isEmpty { continue }
            if weekdays.contains(lower) { continue }
            if lower == "mc" || lower == "light" || lower == "closer" { continue }
            if clean.count < 3 { continue }
            return clean
        }
        return nil
    }
}
