import SwiftUI

@main
struct StageTimePNWApp: App {
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            if authManager.isLoading {
                // Splash screen while checking login session
                ZStack {
                    Color.pnwDarkBg.ignoresSafeArea()
                    ProgressView().tint(.pnwGreen)
                }
            } else if authManager.isAuthenticated {
                // User IS logged in -> Show the main app
                ContentView()
                    .environmentObject(authManager)
            } else {
                // User is NOT logged in -> Show Login/Register
                AuthView()
                    .environmentObject(authManager)
            }
        }
    }
}
