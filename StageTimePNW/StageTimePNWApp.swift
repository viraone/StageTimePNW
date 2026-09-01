import SwiftUI

@main
struct StageTimePNWApp: App {
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            Group {
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
                    // User is NOT logged in -> Show Login screen
                    NavigationView {
                        LoginView()
                            .environmentObject(authManager)
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                }
            }
            // Handle deep links from email verification
            .onOpenURL { url in
                Task {
                    await authManager.handleDeepLink(url: url)
                }
            }
        }
    }
}
