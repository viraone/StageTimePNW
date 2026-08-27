//
//  OpenMic.swift
//  StageTimePNW
//

import Foundation
import CoreLocation

/// Matches the schema of data/open-mics.json from the slotted-killer project
/// (served live at https://stagetimepnw.com/data/open-mics.json).
struct OpenMic: Identifiable, Decodable {
    let id: String
    let name: String
    let location: String
    let latitude: Double
    let longitude: Double

    let timeSignupStart: String?
    let signupType: String?
    let signupDetails: String?
    let priceForTime: String?
    let openMicType: String?
    let ageRequirement: String?
    let requirementsInfo: String?
    let host: String?
    let webSignup: String?
    let recurrenceText: String?
    let website: String?
    let phone: String?
    let venue: String?

    let monday: String?
    let tuesday: String?
    let wednesday: String?
    let thursday: String?
    let friday: String?
    let saturday: String?
    let sunday: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Days of the week this mic runs, e.g. ["Monday", "Thursday"].
    var activeDays: [String] {
        let days: [(String, String?)] = [
            ("Monday", monday), ("Tuesday", tuesday), ("Wednesday", wednesday),
            ("Thursday", thursday), ("Friday", friday), ("Saturday", saturday),
            ("Sunday", sunday)
        ]
        return days
            .filter { $0.1?.lowercased() == "yes" }
            .map { $0.0 }
    }
}
