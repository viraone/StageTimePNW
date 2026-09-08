import XCTest
@testable import StageTimePNW

final class AppConfigTests: XCTestCase {

    func testEnvironmentOverridesBundle() {
        let config = AppConfig.load(
            environment: ["SUPABASE_URL": "http://127.0.0.1:54321", "SUPABASE_ANON_KEY": "local"],
            bundle: .main
        )
        XCTAssertEqual(config.supabaseURL.absoluteString, "http://127.0.0.1:54321")
        XCTAssertEqual(config.supabaseAnonKey, "local")
    }

    func testFallsBackToBundleWhenEnvironmentEmpty() {
        let config = AppConfig.load(environment: ["SUPABASE_URL": "", "SUPABASE_ANON_KEY": ""], bundle: .main)
        XCTAssertEqual(config.supabaseURL.scheme, "https")
        XCTAssertFalse(config.supabaseAnonKey.isEmpty)
        XCTAssertFalse(config.supabaseAnonKey.hasPrefix("$("), "Build setting was not substituted into Info.plist")
    }
}
