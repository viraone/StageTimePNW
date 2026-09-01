import SwiftUI
import Combine

// MARK: - Lineup Entry Model

struct LineupEntry: Identifiable {
    let id = UUID()
    let name: String
    let setLength: String
    let startTime: String
}

// MARK: - Tonight List View Model

@MainActor
class TonightListViewModel: ObservableObject {

    @Published var entries: [LineupEntry] = []
    @Published var isLoading: Bool = false
    @Published var statusMessage: String? = nil

    // Same source as stagetimepnw.com's Friday lineup poster
    private let sheetID = "1CiqV18PMOPVienqn4HrqMVuMkxXX4bDJd08HATQk8gU"
    private let sheetName = "Intake & Contacts"

    /// True from Friday 6:00 AM through Saturday 5:59 AM (Seattle time) —
    /// mirrors getSeattleScheduleMode() on the website.
    var isLineupWindow: Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let comps = calendar.dateComponents([.weekday, .hour], from: Date())
        guard let weekday = comps.weekday, let hour = comps.hour else { return false }
        // weekday: 1 = Sunday ... 6 = Friday, 7 = Saturday
        if weekday == 6 && hour >= 6 { return true }
        if weekday == 7 && hour < 6 { return true }
        return false
    }

    func fetchLineup() async {

        isLoading = true
        statusMessage = nil

        defer { isLoading = false }

        guard
            let encodedSheet = sheetName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: "https://docs.google.com/spreadsheets/d/\(sheetID)/gviz/tq?tqx=out:json&sheet=\(encodedSheet)")
        else {
            statusMessage = "The lineup could not be loaded."
            return
        }

        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let text = String(data: data, encoding: .utf8) else {
                statusMessage = "The lineup could not be loaded. Pull to refresh."
                return
            }

            let parsed = try Self.parseGvizLineup(text)

            if parsed.isEmpty {
                entries = []
                statusMessage = "Tonight's lineup has not been posted yet."
            } else {
                entries = parsed
                statusMessage = nil
            }

        } catch {
            print("Failed to fetch lineup: \(error)")
            statusMessage = "The lineup could not be loaded. Pull to refresh."
        }
    }

    // MARK: - Parse Google Sheets gviz response

    /// The gviz endpoint wraps JSON in `google.visualization.Query.setResponse(...)`.
    static func parseGvizLineup(_ text: String) throws -> [LineupEntry] {

        guard
            let start = text.range(of: "setResponse("),
            let end = text.range(of: ");", options: .backwards)
        else {
            throw URLError(.cannotParseResponse)
        }

        let jsonString = String(text[start.upperBound..<end.lowerBound])
        let jsonData = Data(jsonString.utf8)

        guard
            let payload = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
            payload["status"] as? String == "ok",
            let table = payload["table"] as? [String: Any],
            let cols = table["cols"] as? [[String: Any]],
            let rows = table["rows"] as? [[String: Any]]
        else {
            throw URLError(.cannotParseResponse)
        }

        let labels = cols.map { ($0["label"] as? String ?? "").trimmingCharacters(in: .whitespaces).uppercased() }
        let nameIndex = labels.firstIndex(of: "NAME") ?? -1
        let setIndex = labels.firstIndex(of: "SET") ?? -1
        let timeIndex = labels.firstIndex(of: "TIME") ?? -1

        func cellText(_ row: [String: Any], _ index: Int) -> String {
            guard index >= 0,
                  let cells = row["c"] as? [Any],
                  index < cells.count,
                  let cell = cells[index] as? [String: Any] else { return "" }
            if let formatted = cell["f"] as? String, !formatted.trimmingCharacters(in: .whitespaces).isEmpty {
                return formatted.trimmingCharacters(in: .whitespaces)
            }
            if let value = cell["v"] {
                if value is NSNull { return "" }
                return String(describing: value).trimmingCharacters(in: .whitespaces)
            }
            return ""
        }

        return rows.compactMap { row in
            let name = cellText(row, nameIndex)
            guard !name.isEmpty else { return nil }
            return LineupEntry(
                name: name,
                setLength: Self.formatSetLength(cellText(row, setIndex)),
                startTime: Self.formatStartTime(cellText(row, timeIndex))
            )
        }
    }

    static func formatSetLength(_ value: String) -> String {
        let text = value.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return "—" }
        // Bare numbers become "X MIN", matching the website
        if text.range(of: #"^\d+(\.\d+)?$"#, options: .regularExpression) != nil {
            return "\(text) MIN"
        }
        return text.uppercased()
    }

    static func formatStartTime(_ value: String) -> String {
        let text = value.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return "—" }
        // Convert "19:15" or "19:15:00" to "7:15 PM"
        guard let match = text.range(of: #"^(\d{1,2}):(\d{2})(:\d{2}(\.\d+)?)?$"#, options: .regularExpression) else {
            return text
        }
        let parts = String(text[match]).split(separator: ":")
        guard let hours = Int(parts[0]), hours <= 23 else { return text }
        let minutes = String(parts[1])
        let suffix = hours >= 12 ? "PM" : "AM"
        let displayHours = hours % 12 == 0 ? 12 : hours % 12
        return "\(displayHours):\(minutes) \(suffix)"
    }
}

// MARK: - Tonight List View (Rickshaw Friday Lineup Poster)

struct TonightListView: View {

    @StateObject private var viewModel = TonightListViewModel()

    private let posterGold = Color(red: 0.95, green: 0.78, blue: 0.35)
    private let posterRed = Color(red: 1.0, green: 0.35, blue: 0.35)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    // MARK: Poster Header
                    VStack(spacing: 10) {
                        Text("LIVE AT THE RICKSHAW LOUNGE")
                            .font(.system(size: 11, weight: .heavy))
                            .tracking(3)
                            .foregroundColor(posterGold)

                        Image("RickshawLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 70)

                        (Text("TONIGHT'S ")
                            .foregroundColor(.white)
                        + Text("LINEUP")
                            .foregroundColor(posterRed))
                            .font(.system(size: 30, weight: .black))
                            .tracking(1)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 20)

                    // MARK: Lineup Board
                    VStack(spacing: 0) {

                        // Column headers
                        HStack {
                            Text("PERFORMER")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("SET")
                                .frame(width: 70, alignment: .trailing)
                            Text("TIME")
                                .frame(width: 80, alignment: .trailing)
                        }
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(1.5)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        Rectangle()
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 1)

                        if viewModel.isLoading && viewModel.entries.isEmpty {
                            ProgressView("Loading tonight's lineup...")
                                .tint(posterGold)
                                .foregroundColor(.gray)
                                .padding(.vertical, 40)

                        } else if let message = viewModel.statusMessage {
                            VStack(spacing: 8) {
                                Image(systemName: "moon.stars")
                                    .font(.system(size: 28))
                                    .foregroundColor(.gray)
                                Text(message)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                if !viewModel.isLineupWindow {
                                    Text("The lineup goes live every Friday.")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray.opacity(0.7))
                                }
                            }
                            .padding(.vertical, 40)
                            .padding(.horizontal, 20)

                        } else {
                            ForEach(Array(viewModel.entries.enumerated()), id: \.element.id) { index, entry in
                                HStack {
                                    Text(entry.name.uppercased())
                                        .font(.system(size: 16, weight: .heavy))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    Text(entry.setLength)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(posterGold)
                                        .frame(width: 70, alignment: .trailing)

                                    Text(entry.startTime)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.gray)
                                        .frame(width: 80, alignment: .trailing)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(index.isMultiple(of: 2) ? Color.clear : Color.white.opacity(0.03))

                                if index < viewModel.entries.count - 1 {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.06))
                                        .frame(height: 1)
                                }
                            }
                        }
                    }
                    .background(Color(white: 0.07))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(posterGold.opacity(0.35), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)

                    // MARK: Poster Footer
                    HStack(spacing: 8) {
                        Text("READ THE ROOM")
                        Text("◆").foregroundColor(posterRed)
                        Text("FRIDAY NIGHT")
                    }
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(2)
                    .foregroundColor(.gray)
                    .padding(.vertical, 24)
                }
            }
            .refreshable {
                await viewModel.fetchLineup()
            }
        }
        .task {
            await viewModel.fetchLineup()
        }
    }
}

#Preview {
    TonightListView()
}
