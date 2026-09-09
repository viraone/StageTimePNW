import Foundation

struct OpenMic: Codable, Identifiable {
    let id: String
    let name: String
    let location: String
    let timeSignupStart: String?
    let signupType: String?
    let signupDetails: String?
    let monday: String?
    let tuesday: String?
    let wednesday: String?
    let thursday: String?
    let friday: String?
    let saturday: String?
    let sunday: String?
    let priceForTime: String?
    let openMicType: String?
    let ageRequirement: String?
    let requirementsInfo: String?
    let host: String?
    let contact: String?
    let webSignup: String?
    let recurrenceText: String?
    let recurrence: Recurrence?
    let latitude: Double?
    let longitude: Double?
    let venue: String?
    let website: String?
    let phone: String?
    let wheelchairAccessible: Bool?
    let showWhenInactive: Bool?
    let listLabel: String?
    let listUrl: String?
    let listSourceUrl: String?
    let source: Source?

    struct Recurrence: Codable {
        let type: String?
        let weekday: String?
    }

    struct Source: Codable {
        let name: String?
        let url: String?
    }

    func isActive(on day: Weekday) -> Bool {
        switch day {
        case .sun: return sunday?.lowercased() == "yes"
        case .mon: return monday?.lowercased() == "yes"
        case .tue: return tuesday?.lowercased() == "yes"
        case .wed: return wednesday?.lowercased() == "yes"
        case .thu: return thursday?.lowercased() == "yes"
        case .fri: return friday?.lowercased() == "yes"
        case .sat: return saturday?.lowercased() == "yes"
        }
    }

    // MARK: - Time Parsing Helpers (Matches Desktop Website)

    /// Formatted Show Start Time, e.g. "6:00 PM"
    var displayStartTime: String? {
        guard let raw = timeSignupStart, !raw.isEmpty else { return nil }
        let parts = raw.split(separator: "/", omittingEmptySubsequences: false)
        let showPart = parts.count > 1 ? String(parts[1]) : String(parts[0])
        let clean = showPart.components(separatedBy: "-").first ?? showPart
        return formatTimeToken(clean)
    }

    /// Formatted Signup Time, e.g. "5:30 PM" or "Online"
    var displaySignupTime: String? {
        guard let raw = timeSignupStart, !raw.isEmpty else { return nil }
        let parts = raw.split(separator: "/", omittingEmptySubsequences: false)
        guard parts.count > 1, !parts[0].isEmpty else { return nil }
        let signupPart = String(parts[0])
        if signupPart.lowercased().contains("online") { return "Online" }
        return formatTimeToken(signupPart)
    }

    /// Combined display line: "Start 6:00 PM · Signup 5:30 PM"
    var timeSubtitle: String {
        var items: [String] = []
        if let start = displayStartTime {
            items.append("Start \(start)")
        }
        if let signup = displaySignupTime {
            items.append("Signup \(signup)")
        }
        return items.isEmpty ? (timeSignupStart ?? "") : items.joined(separator: " · ")
    }

    /// Sort key in minutes from midnight (e.g. 6:00 PM -> 1080)
    var startMinutesFromMidnight: Int {
        guard let raw = timeSignupStart, !raw.isEmpty else { return 9999 }
        let parts = raw.split(separator: "/", omittingEmptySubsequences: false)
        let showPart = parts.count > 1 ? String(parts[1]) : String(parts[0])
        let clean = (showPart.components(separatedBy: "-").first ?? showPart).trimmingCharacters(in: .whitespaces).lowercased()
        
        let isPM = clean.contains("pm")
        let digitsOnly = clean.replacingOccurrences(of: "pm", with: "").replacingOccurrences(of: "am", with: "").trimmingCharacters(in: .whitespaces)
        
        let timeComponents = digitsOnly.split(separator: ":")
        guard let hourInt = Int(timeComponents[0]) else { return 9999 }
        let minuteInt = timeComponents.count > 1 ? (Int(timeComponents[1]) ?? 0) : 0
        
        var hour = hourInt
        if isPM && hour < 12 { hour += 12 }
        if !isPM && hour == 12 { hour = 0 }
        
        return (hour * 60) + minuteInt
    }

    private func formatTimeToken(_ token: String) -> String {
        let trimmed = token.trimmingCharacters(in: .whitespaces).lowercased()
        let isPM = trimmed.contains("pm")
        let isAM = trimmed.contains("am")
        let clean = trimmed.replacingOccurrences(of: "pm", with: "").replacingOccurrences(of: "am", with: "").trimmingCharacters(in: .whitespaces)
        
        let parts = clean.split(separator: ":")
        guard let hour = parts.first else { return token }
        let min = parts.count > 1 ? String(parts[1]) : "00"
        let suffix = isPM ? "PM" : (isAM ? "AM" : "PM")
        return "\(hour):\(min) \(suffix)"
    }
}
