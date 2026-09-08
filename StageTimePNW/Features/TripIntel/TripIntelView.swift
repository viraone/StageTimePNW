import SwiftUI
import Combine
import CoreLocation
import UIKit

// MARK: - Location Service

@MainActor
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var location: CLLocation? = nil
    @Published var isDenied: Bool = false

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func request() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            isDenied = true
        default:
            manager.requestLocation()
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.isDenied = false
                self.manager.requestLocation()
            case .denied, .restricted:
                self.isDenied = true
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        Task { @MainActor in
            self.location = latest
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
}

// MARK: - Trip Math (mirrors the website's estimates)

enum TripMath {

    static func miles(from location: CLLocation, to mic: OpenMic) -> Double? {
        guard let lat = mic.latitude, let lon = mic.longitude else { return nil }
        let venue = CLLocation(latitude: lat, longitude: lon)
        return location.distance(from: venue) / 1609.34
    }

    /// Rough urban drive estimate, like the site's distance-based guess.
    static func driveMinutes(forMiles miles: Double) -> Int {
        max(3, Int((miles * 60.0 / 24.0).rounded()) + 2)
    }

    static func trafficLabel(forDriveMinutes minutes: Int) -> (label: String, color: Color) {
        if minutes <= 20 { return ("Clear", Color(red: 0.05, green: 0.82, blue: 0.45)) }
        if minutes <= 35 { return ("Moderate", .yellow) }
        return ("Heavy", Color(red: 1.0, green: 0.35, blue: 0.35))
    }
}

// MARK: - Weather (Open-Meteo, no key needed)

struct TripWeather {
    let temperature: Int
    let feelsLike: Int
    let emoji: String
    let label: String
    let precipitation: Double

    var precipitationText: String {
        precipitation > 0 ? "Precipitation now" : "No current precipitation"
    }
}

// MARK: - Parking summary (OpenStreetMap Overpass)

struct TripParking {
    let summary: String
    let huntMinutes: Int
}

// MARK: - Transit (OneBusAway Puget Sound)

struct TripTransitArrival: Identifiable {
    let id = UUID()
    let routeName: String
    let stopName: String
    let minutesUntil: Int
}

// MARK: - Trip Intel Service

enum TripIntelService {

    static func fetchWeather(lat: Double, lon: Double) async throws -> TripWeather {
        var comps = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        comps.queryItems = [
            URLQueryItem(name: "latitude", value: String(lat)),
            URLQueryItem(name: "longitude", value: String(lon)),
            URLQueryItem(name: "current", value: "temperature_2m,apparent_temperature,precipitation,weather_code"),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
            URLQueryItem(name: "precipitation_unit", value: "inch")
        ]
        let (data, _) = try await URLSession.shared.data(from: comps.url!)
        guard
            let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let current = payload["current"] as? [String: Any],
            let temp = current["temperature_2m"] as? Double,
            let feels = current["apparent_temperature"] as? Double
        else { throw URLError(.cannotParseResponse) }

        let code = current["weather_code"] as? Int ?? -1
        let precip = current["precipitation"] as? Double ?? 0
        let condition = weatherCondition(code)
        return TripWeather(
            temperature: Int(temp.rounded()),
            feelsLike: Int(feels.rounded()),
            emoji: condition.emoji,
            label: condition.label,
            precipitation: precip
        )
    }

    static func weatherCondition(_ code: Int) -> (emoji: String, label: String) {
        switch code {
        case 0: return ("☀️", "Clear")
        case 1: return ("🌤️", "Mostly clear")
        case 2, 3: return ("⛅", "Partly cloudy")
        case 45, 48: return ("🌫️", "Fog")
        case 51, 53, 55, 56, 57: return ("🌦️", "Drizzle")
        case 61, 63, 65, 66, 67: return ("🌧️", "Rain")
        case 71, 73, 75, 77: return ("🌨️", "Snow")
        case 80, 81, 82: return ("🌦️", "Rain showers")
        case 85, 86: return ("🌨️", "Snow showers")
        case 95, 96, 99: return ("⛈️", "Thunderstorms")
        default: return ("🌡️", "Conditions unavailable")
        }
    }

    static func fetchParking(lat: Double, lon: Double) async throws -> TripParking {
        let query = "[out:json][timeout:8];nwr[\"amenity\"=\"parking\"](around:300,\(lat),\(lon));out tags center;"
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://overpass-api.de/api/interpreter?data=\(encoded)") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        guard
            let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let elements = payload["elements"] as? [[String: Any]]
        else { throw URLError(.cannotParseResponse) }

        guard !elements.isEmpty else {
            return TripParking(summary: "No mapped parking within 300 m — expect street parking.", huntMinutes: 8)
        }

        let hasFree = elements.contains { element in
            let tags = element["tags"] as? [String: Any]
            return (tags?["fee"] as? String)?.lowercased() == "no"
        }
        let typeText = hasFree
            ? "Free parking is mapped nearby."
            : "Paid parking or meters are mapped nearby."
        let count = elements.count
        let summary = "\(count) mapped parking \(count == 1 ? "option" : "options") within 300 m. \(typeText)"
        let hunt = count >= 4 ? 4 : (hasFree ? 6 : 7)
        return TripParking(summary: summary, huntMinutes: hunt)
    }

    // Same public demo key the website uses
    private static let obaKey = "ceb473d5-b12a-4833-82da-c4c721a62f17"
    private static let obaBase = "https://api.pugetsound.onebusaway.org/api/where"

    static func fetchTransit(lat: Double, lon: Double) async throws -> [TripTransitArrival] {

        // 1. Find nearby stops
        guard let stopsURL = URL(string: "\(obaBase)/stops-for-location.json?key=\(obaKey)&lat=\(lat)&lon=\(lon)&radius=400") else {
            throw URLError(.badURL)
        }
        let (stopsData, _) = try await URLSession.shared.data(from: stopsURL)
        guard
            let stopsPayload = try JSONSerialization.jsonObject(with: stopsData) as? [String: Any],
            let stopsWrap = stopsPayload["data"] as? [String: Any],
            let stops = stopsWrap["list"] as? [[String: Any]],
            let nearest = stops.first,
            let stopID = nearest["id"] as? String
        else { return [] }

        let stopName = nearest["name"] as? String ?? "Nearby stop"

        // 2. Upcoming arrivals at the nearest stop
        guard let arrivalsURL = URL(string: "\(obaBase)/arrivals-and-departures-for-stop/\(stopID).json?key=\(obaKey)&minutesAfter=60") else {
            return []
        }
        let (arrData, _) = try await URLSession.shared.data(from: arrivalsURL)
        guard
            let arrPayload = try JSONSerialization.jsonObject(with: arrData) as? [String: Any],
            let arrWrap = arrPayload["data"] as? [String: Any],
            let entry = arrWrap["entry"] as? [String: Any],
            let arrivals = entry["arrivalsAndDepartures"] as? [[String: Any]]
        else { return [] }

        let nowMs = Date().timeIntervalSince1970 * 1000

        return arrivals.prefix(3).compactMap { arrival in
            let route = arrival["routeShortName"] as? String ?? "Route"
            let predicted = arrival["predictedArrivalTime"] as? Double ?? 0
            let scheduled = arrival["scheduledArrivalTime"] as? Double ?? 0
            let arrivalMs = predicted > 0 ? predicted : scheduled
            guard arrivalMs > 0 else { return nil }
            let minutes = max(0, Int(((arrivalMs - nowMs) / 60000).rounded()))
            return TripTransitArrival(routeName: route, stopName: stopName, minutesUntil: minutes)
        }
    }
}

// MARK: - Trip Intel Sheet

struct TripIntelSheet: View {

    let mic: OpenMic
    let userLocation: CLLocation?

    @Environment(\.dismiss) private var dismiss

    @State private var weather: TripWeather? = nil
    @State private var parking: TripParking? = nil
    @State private var transit: [TripTransitArrival] = []
    @State private var transitFailed = false

    private let pnwGreen = Color(red: 0.05, green: 0.82, blue: 0.45)
    private let pnwRed = Color(red: 1.0, green: 0.35, blue: 0.35)

    private var miles: Double? {
        guard let userLocation else { return nil }
        return TripMath.miles(from: userLocation, to: mic)
    }

    private var driveMinutes: Int? {
        guard let miles else { return nil }
        return TripMath.driveMinutes(forMiles: miles)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // MARK: Commute & Travel Time
                    sectionCard {
                        sectionHeader("🚦", "COMMUTE & TRAVEL TIME")

                        if let miles {
                            Text("Current location ➜ \(mic.name) (\(String(format: "%.1f", miles)) mi)")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                        } else {
                            Text("Turn on location to see drive times.")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }

                        HStack(spacing: 10) {
                            statBox(title: "🚗 DRIVE", value: driveMinutes.map { "\($0) min" } ?? "—")
                            statBox(title: "🅿️ PARKING", value: parking.map { "+\($0.huntMinutes) min" } ?? "…")
                            statBox(
                                title: "TOTAL DRIVE",
                                value: totalText,
                                valueColor: pnwGreen,
                                border: pnwGreen.opacity(0.6)
                            )
                        }
                    }

                    // MARK: Live Transit
                    sectionCard {
                        sectionHeader("🚌", "LIVE PUGET SOUND TRANSIT")

                        if transitFailed {
                            Text("Live transit feed temporarily busy. Tap \"Bus Routes\" below for the full schedule.")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        } else if transit.isEmpty {
                            HStack(spacing: 8) {
                                ProgressView().tint(pnwGreen)
                                Text("Checking nearby stops…")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                        } else {
                            ForEach(transit) { arrival in
                                TransitArrivalRow(arrival: arrival)
                            }
                        }
                    }

                    // MARK: Weather
                    sectionCard {
                        sectionHeader("🌦", "LOCAL WEATHER")

                        if let weather {
                            Text("\(weather.emoji) \(weather.temperature)°F (feels \(weather.feelsLike)°)   \(weather.label) · \(weather.precipitationText)")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        } else {
                            Text("Loading live conditions…")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                    }

                    // MARK: Parking & Venue Access
                    sectionCard {
                        sectionHeader("🅿️", "PARKING & VENUE ACCESS")

                        infoRow("Parking", parking?.summary ?? "Checking nearby parking…")
                        infoRow("Sign-up", mic.signupDetails?.isEmpty == false
                                ? mic.signupDetails!
                                : "Check with host or bar staff upon arrival.")
                    }

                    // MARK: Action Buttons
                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            actionButton("🚌 Bus Routes", background: Color(white: 0.12), border: .blue) {
                                openGoogleMaps(travelMode: "transit")
                            }
                            actionButton("🗺 Apple Maps", background: Color(white: 0.12)) {
                                openAppleMaps()
                            }
                        }
                        actionButton("📍 Google Maps", background: Color(white: 0.12)) {
                            openGoogleMaps(travelMode: "driving")
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle(mic.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.gray)
                }
            }
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .task { await loadIntel() }
    }

    private var totalText: String {
        guard let driveMinutes else { return "—" }
        let hunt = parking?.huntMinutes ?? 0
        return "\(driveMinutes + hunt) min"
    }

    private func loadIntel() async {
        guard let lat = mic.latitude, let lon = mic.longitude else { return }

        async let weatherTask: () = fetchWeather(lat: lat, lon: lon)
        async let parkingTask: () = fetchParking(lat: lat, lon: lon)
        async let transitTask: () = fetchTransit(lat: lat, lon: lon)
        _ = await (weatherTask, parkingTask, transitTask)
    }

    private func fetchWeather(lat: Double, lon: Double) async {
        weather = try? await TripIntelService.fetchWeather(lat: lat, lon: lon)
    }

    private func fetchParking(lat: Double, lon: Double) async {
        parking = (try? await TripIntelService.fetchParking(lat: lat, lon: lon))
            ?? TripParking(summary: "Parking data unavailable — check posted signs.", huntMinutes: 5)
    }

    private func fetchTransit(lat: Double, lon: Double) async {
        do {
            let arrivals = try await TripIntelService.fetchTransit(lat: lat, lon: lon)
            transit = arrivals
            transitFailed = arrivals.isEmpty
        } catch {
            transitFailed = true
        }
    }

    // MARK: Map links

    private func openAppleMaps() {
        guard let url = URL(string: "https://maps.apple.com/?daddr=\(mic.location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else { return }
        UIApplication.shared.open(url)
    }

    private func openGoogleMaps(travelMode: String) {
        let destination = mic.location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        var origin = ""
        if let userLocation {
            origin = "&origin=\(userLocation.coordinate.latitude),\(userLocation.coordinate.longitude)"
        }
        guard let url = URL(string: "https://www.google.com/maps/dir/?api=1\(origin)&destination=\(destination)&travelmode=\(travelMode)") else { return }
        UIApplication.shared.open(url)
    }

    // MARK: Small view builders

    @ViewBuilder
    private func sectionCard(@ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(white: 0.07))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    private func sectionHeader(_ emoji: String, _ title: String) -> some View {
        Text("\(emoji) \(title)")
            .font(.system(size: 11, weight: .heavy))
            .tracking(1.5)
            .foregroundColor(.gray)
    }

    private func statBox(title: String, value: String, valueColor: Color = .white, border: Color = Color.white.opacity(0.1)) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(white: 0.10))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(border, lineWidth: 1))
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.gray)
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(.system(size: 13))
                .foregroundColor(.white)
        }
    }

    private func actionButton(_ title: String, background: Color, border: Color = Color.white.opacity(0.15), action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(background)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(border, lineWidth: 1))
        }
    }
}

// MARK: - Transit Row

struct TransitArrivalRow: View {
    let arrival: TripTransitArrival

    private var etaText: String {
        arrival.minutesUntil == 0 ? "now" : "in \(arrival.minutesUntil) min"
    }

    var body: some View {
        HStack {
            Text(arrival.routeName)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.blue)
                .cornerRadius(6)

            Text(arrival.stopName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            Text(etaText)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.orange)
        }
        .padding(.vertical, 4)
    }
}
