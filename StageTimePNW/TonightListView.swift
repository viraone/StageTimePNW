import SwiftUI
import Combine
import Supabase
import UserNotifications

// MARK: - Lineup Entry Model

enum PerformerStatus: String, Codable {
    case waiting
    case performing
    case done
}

struct LineupEntry: Identifiable, Codable {
    let id: Int
    let position: Int
    let name: String
    let email: String?
    let setLength: String?
    let startTime: String?
    let status: PerformerStatus

    enum CodingKeys: String, CodingKey {
        case id, position, name, email, status
        case setLength = "set_length"
        case startTime = "start_time"
    }
}

// Row payload for importing the lineup into Supabase (host action)
private struct NewLineupRow: Encodable {
    let show_date: String
    let position: Int
    let name: String
    let email: String?
    let set_length: String?
    let start_time: String?
}

// MARK: - Tonight List View Model

@MainActor
class TonightListViewModel: ObservableObject {

    @Published var entries: [LineupEntry] = []
    @Published var isLoading: Bool = false
    @Published var statusMessage: String? = nil
    @Published var isAdmin: Bool = false
    @Published var isWorking: Bool = false   // host action in flight

    private var currentUserEmail: String? = nil
    private var lastNotifiedEntryID: Int? = nil
    private var pollTask: Task<Void, Never>? = nil

    // Same sheet that powers stagetimepnw.com's Friday lineup poster
    private let sheetID = "1CiqV18PMOPVienqn4HrqMVuMkxXX4bDJd08HATQk8gU"
    private let sheetName = "Intake & Contacts"

    // MARK: - Derived show state

    var performingEntry: LineupEntry? {
        entries.first { $0.status == .performing }
    }

    /// On deck = the first waiting performer after the show has started
    var onDeckEntry: LineupEntry? {
        guard performingEntry != nil else { return nil }
        return entries.filter { $0.status == .waiting }.min { $0.position < $1.position }
    }

    var showHasStarted: Bool {
        entries.contains { $0.status != .waiting }
    }

    /// Today's date in Seattle, matching the DB default
    static var seattleToday: String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "America/Los_Angeles")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    // MARK: - Lifecycle

    func start() async {
        await loadUserContext()
        await fetchLineup()
        startPolling()
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
    }

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(15))
                guard !Task.isCancelled else { break }
                await self?.fetchLineup(quiet: true)
            }
        }
    }

    private func loadUserContext() async {
        currentUserEmail = try? await supabase.auth.session.user.email

        do {
            isAdmin = try await supabase
                .rpc("is_app_admin")
                .execute()
                .value
        } catch {
            isAdmin = false
        }

        if isAdmin {
            // Hosts don't need on-deck alerts, comedians do — ask everyone anyway
            _ = try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } else {
            _ = try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        }
    }

    // MARK: - Fetch lineup (Supabase first, sheet fallback)

    func fetchLineup(quiet: Bool = false) async {
        if !quiet { isLoading = true }
        defer { if !quiet { isLoading = false } }

        do {
            let rows: [LineupEntry] = try await supabase
                .from("show_lineup")
                .select("id, position, name, email, set_length, start_time, status")
                .eq("show_date", value: Self.seattleToday)
                .order("position")
                .execute()
                .value

            if rows.isEmpty {
                await fetchLineupFromSheetFallback()
            } else {
                entries = rows
                statusMessage = nil
                notifyIfOnDeck()
            }
        } catch {
            print("Failed to fetch live lineup: \(error)")
            await fetchLineupFromSheetFallback()
        }
    }

    /// Read-only fallback: show the Google Sheet lineup when the host
    /// hasn't imported tonight's show yet.
    private func fetchLineupFromSheetFallback() async {
        do {
            let sheetRows = try await Self.fetchSheetLineup(sheetID: sheetID, sheetName: sheetName)
            if sheetRows.isEmpty {
                entries = []
                statusMessage = "Tonight's lineup has not been posted yet."
            } else {
                entries = sheetRows.enumerated().map { index, row in
                    LineupEntry(
                        id: -(index + 1), // synthetic IDs for sheet-only mode
                        position: index + 1,
                        name: row.name,
                        email: row.email,
                        setLength: row.setLength,
                        startTime: row.startTime,
                        status: .waiting
                    )
                }
                statusMessage = nil
            }
        } catch {
            print("Failed to fetch sheet lineup: \(error)")
            if entries.isEmpty {
                statusMessage = "The lineup could not be loaded. Pull to refresh."
            }
        }
    }

    // MARK: - Host actions

    /// Import tonight's sheet into Supabase so the host can run the show.
    func importLineup() async {
        guard isAdmin else { return }
        isWorking = true
        defer { isWorking = false }

        do {
            let sheetRows = try await Self.fetchSheetLineup(sheetID: sheetID, sheetName: sheetName)
            guard !sheetRows.isEmpty else {
                statusMessage = "The sheet has no performers to import."
                return
            }

            // Replace today's lineup
            try await supabase
                .from("show_lineup")
                .delete()
                .eq("show_date", value: Self.seattleToday)
                .execute()

            let newRows = sheetRows.enumerated().map { index, row in
                NewLineupRow(
                    show_date: Self.seattleToday,
                    position: index + 1,
                    name: row.name,
                    email: row.email,
                    set_length: row.setLength,
                    start_time: row.startTime
                )
            }

            try await supabase
                .from("show_lineup")
                .insert(newRows)
                .execute()

            await fetchLineup(quiet: true)
        } catch {
            print("Import failed: \(error)")
            statusMessage = "Import failed. Try again."
        }
    }

    /// Host taps "Next Comic" (or "Start Show" for the first performer).
    func nextComic() async {
        guard isAdmin else { return }
        isWorking = true
        defer { isWorking = false }

        do {
            let rows: [LineupEntry] = try await supabase
                .rpc("advance_lineup")
                .execute()
                .value
            entries = rows
            notifyIfOnDeck()
        } catch {
            print("Advance failed: \(error)")
            statusMessage = "Could not advance the lineup."
        }
    }

    /// Host resets everyone back to waiting.
    func resetShow() async {
        guard isAdmin else { return }
        isWorking = true
        defer { isWorking = false }

        do {
            try await supabase.rpc("reset_lineup").execute()
            await fetchLineup(quiet: true)
        } catch {
            print("Reset failed: \(error)")
        }
    }

    // MARK: - On-deck local notification

    private func notifyIfOnDeck() {
        guard
            let onDeck = onDeckEntry,
            let myEmail = currentUserEmail,
            let entryEmail = onDeck.email,
            entryEmail.lowercased() == myEmail.lowercased(),
            lastNotifiedEntryID != onDeck.id
        else { return }

        lastNotifiedEntryID = onDeck.id

        let content = UNMutableNotificationContent()
        content.title = "🎤 You're ON DECK!"
        content.body = "\(performingEntry?.name ?? "The current comic") is up now — head toward the stage."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "on-deck-\(onDeck.id)",
            content: content,
            trigger: nil // fire immediately
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Google Sheet fetch + parse

    struct SheetRow {
        let name: String
        let email: String?
        let setLength: String?
        let startTime: String?
    }

    static func fetchSheetLineup(sheetID: String, sheetName: String) async throws -> [SheetRow] {
        guard
            let encodedSheet = sheetName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: "https://docs.google.com/spreadsheets/d/\(sheetID)/gviz/tq?tqx=out:json&sheet=\(encodedSheet)")
        else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200,
              let text = String(data: data, encoding: .utf8) else {
            throw URLError(.badServerResponse)
        }

        return try parseGvizLineup(text)
    }

    /// The gviz endpoint wraps JSON in `google.visualization.Query.setResponse(...)`.
    static func parseGvizLineup(_ text: String) throws -> [SheetRow] {

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
        let emailIndex = labels.firstIndex(of: "EMAIL") ?? -1

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
            let email = cellText(row, emailIndex)
            return SheetRow(
                name: name,
                email: email.isEmpty ? nil : email,
                setLength: formatSetLength(cellText(row, setIndex)),
                startTime: formatStartTime(cellText(row, timeIndex))
            )
        }
    }

    static func formatSetLength(_ value: String) -> String? {
        let text = value.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }
        if text.range(of: #"^\d+(\.\d+)?$"#, options: .regularExpression) != nil {
            return "\(text) MIN"
        }
        return text.uppercased()
    }

    static func formatStartTime(_ value: String) -> String? {
        let text = value.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }
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

                        if let performing = viewModel.performingEntry {
                            LiveNowBanner(name: performing.name, accent: posterRed)
                        }
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 16)

                    // MARK: Host Controls (admin only)
                    if viewModel.isAdmin {
                        HostControls(viewModel: viewModel, posterRed: posterRed, posterGold: posterGold)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                    }

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

                        } else if let message = viewModel.statusMessage, viewModel.entries.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "moon.stars")
                                    .font(.system(size: 28))
                                    .foregroundColor(.gray)
                                Text(message)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                Text("The lineup goes live every Friday.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray.opacity(0.7))
                            }
                            .padding(.vertical, 40)
                            .padding(.horizontal, 20)

                        } else {
                            let onDeckID = viewModel.onDeckEntry?.id
                            ForEach(Array(viewModel.entries.enumerated()), id: \.element.id) { index, entry in
                                LineupRow(
                                    entry: entry,
                                    isOnDeck: entry.id == onDeckID,
                                    posterGold: posterGold,
                                    posterRed: posterRed
                                )
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
            await viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
    }
}

// MARK: - Live Banner

private struct LiveNowBanner: View {
    let name: String
    let accent: Color

    @State private var pulsing = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(accent)
                .frame(width: 8, height: 8)
                .opacity(pulsing ? 0.3 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulsing)

            Text("LIVE NOW: \(name.uppercased())")
                .font(.system(size: 12, weight: .heavy))
                .tracking(1)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(accent.opacity(0.18))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(accent.opacity(0.6), lineWidth: 1)
        )
        .onAppear { pulsing = true }
    }
}

// MARK: - Host Controls

private struct HostControls: View {
    @ObservedObject var viewModel: TonightListViewModel
    let posterRed: Color
    let posterGold: Color

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 12))
                    .foregroundColor(posterGold)
                Text("HOST MODE")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(2)
                    .foregroundColor(posterGold)
                Spacer()
            }

            // Big Next Comic button
            Button {
                Task { await viewModel.nextComic() }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isWorking {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "forward.fill")
                        Text(viewModel.showHasStarted ? "Next Comic" : "Start Show")
                            .fontWeight(.bold)
                    }
                }
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(posterRed)
                .cornerRadius(10)
            }
            .disabled(viewModel.isWorking || viewModel.entries.isEmpty)

            HStack(spacing: 10) {
                Button {
                    Task { await viewModel.importLineup() }
                } label: {
                    Label("Import Lineup", systemImage: "square.and.arrow.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(white: 0.15))
                        .cornerRadius(8)
                }
                .disabled(viewModel.isWorking)

                Button {
                    Task { await viewModel.resetShow() }
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(white: 0.15))
                        .cornerRadius(8)
                }
                .disabled(viewModel.isWorking || !viewModel.showHasStarted)
            }
        }
        .padding(14)
        .background(Color(white: 0.06))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(posterGold.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Lineup Row

private struct LineupRow: View {
    let entry: LineupEntry
    let isOnDeck: Bool
    let posterGold: Color
    let posterRed: Color

    @State private var pulsing = false

    private var isDone: Bool { entry.status == .done }
    private var isPerforming: Bool { entry.status == .performing }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    if isDone {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.gray.opacity(0.6))
                    }

                    if isPerforming {
                        Circle()
                            .fill(posterRed)
                            .frame(width: 8, height: 8)
                            .opacity(pulsing ? 0.3 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulsing)
                            .onAppear { pulsing = true }
                    }

                    Text(entry.name.uppercased())
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(isDone ? .gray.opacity(0.5) : (isPerforming ? posterRed : .white))
                        .strikethrough(isDone, color: .gray.opacity(0.4))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                if isPerforming {
                    Text("NOW PERFORMING")
                        .font(.system(size: 9, weight: .heavy))
                        .tracking(1.5)
                        .foregroundColor(posterRed)
                } else if isOnDeck {
                    Text("ON DECK 🎤")
                        .font(.system(size: 9, weight: .heavy))
                        .tracking(1.5)
                        .foregroundColor(posterGold)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(entry.setLength ?? "—")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isDone ? .gray.opacity(0.4) : posterGold)
                .frame(width: 70, alignment: .trailing)

            Text(entry.startTime ?? "—")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isDone ? .gray.opacity(0.4) : .gray)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            isPerforming ? posterRed.opacity(0.10) :
            isOnDeck ? posterGold.opacity(0.07) : Color.clear
        )
        .overlay(
            Rectangle()
                .fill(isPerforming ? posterRed : (isOnDeck ? posterGold : Color.clear))
                .frame(width: 3),
            alignment: .leading
        )
    }
}

#Preview {
    TonightListView()
}
