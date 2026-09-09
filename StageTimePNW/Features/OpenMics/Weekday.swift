import SwiftUI

// MARK: - Enums
enum Weekday: String, CaseIterable, Identifiable {
    case sun = "Sun", mon = "Mon", tue = "Tue", wed = "Wed", thu = "Thu", fri = "Fri", sat = "Sat"
    var id: String { rawValue }

    var fullName: String {
        switch self {
        case .sun: return "Sunday"
        case .mon: return "Monday"
        case .tue: return "Tuesday"
        case .wed: return "Wednesday"
        case .thu: return "Thursday"
        case .fri: return "Friday"
        case .sat: return "Saturday"
        }
    }

    /// Today's weekday, e.g. .thu on a Thursday.
    static var today: Weekday {
        // Calendar weekday: 1 = Sunday ... 7 = Saturday
        let index = Calendar.current.component(.weekday, from: Date()) - 1
        return Weekday.allCases[index]
    }
}

enum MicFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case comedyOnly = "Comedy Only"
    case mix = "Mix Mic"
    
    var id: String { rawValue }
}
