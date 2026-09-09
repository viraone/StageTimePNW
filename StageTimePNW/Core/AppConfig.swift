import Foundation

/// Resolved runtime configuration.
///
/// Resolution order for each key:
/// 1. Process environment (`ProcessInfo`) — lets UI automation (Appium
///    `processArguments.env`) or a scheme point the app at a local backend.
/// 2. `Info.plist`, populated from per-configuration build settings
///    (`SUPABASE_URL`, `SUPABASE_ANON_KEY`).
///
/// Missing configuration is a programmer error and fails fast at launch.
struct AppConfig: Sendable {
    let supabaseURL: URL
    let supabaseAnonKey: String

    static let current: AppConfig = load()

    enum Key: String {
        case supabaseURL = "SUPABASE_URL"
        case supabaseAnonKey = "SUPABASE_ANON_KEY"
    }

    static func load(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        bundle: Bundle = .main
    ) -> AppConfig {
        func value(_ key: Key) -> String {
            if let env = environment[key.rawValue], !env.isEmpty { return env }
            if let plist = bundle.object(forInfoDictionaryKey: key.rawValue) as? String,
               !plist.isEmpty, !plist.hasPrefix("$(") {
                return plist
            }
            fatalError("Missing configuration for \(key.rawValue). Set it in the build settings or the process environment.")
        }

        guard let url = URL(string: value(.supabaseURL)) else {
            fatalError("SUPABASE_URL is not a valid URL.")
        }
        return AppConfig(supabaseURL: url, supabaseAnonKey: value(.supabaseAnonKey))
    }
}
