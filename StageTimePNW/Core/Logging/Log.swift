import Foundation
import OSLog

/// Centralised loggers. Prefer these over `print`; interpolate user data with
/// `privacy: .private` so it is redacted in release logs.
enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.viradeth.StageTimePNW"

    static let auth = Logger(subsystem: subsystem, category: "auth")
    static let network = Logger(subsystem: subsystem, category: "network")
    static let openMics = Logger(subsystem: subsystem, category: "openMics")
    static let lineup = Logger(subsystem: subsystem, category: "lineup")
    static let location = Logger(subsystem: subsystem, category: "location")
    static let ui = Logger(subsystem: subsystem, category: "ui")
}
