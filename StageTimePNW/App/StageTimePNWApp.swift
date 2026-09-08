import SwiftUI

@main
struct StageTimePNWApp: App {
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .onOpenURL { url in
                    Task { await authManager.handleDeepLink(url: url) }
                }
        }
    }
}

/// Switches between splash, auth, and the signed-in app based on session state.
struct RootView: View {
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        Group {
            if authManager.isLoading {
                ZStack {
                    Color.pnwDarkBg.ignoresSafeArea()
                    ProgressView().tint(.pnwGreen)
                }
                .accessibilityIdentifier("root_splash")
            } else if authManager.isAuthenticated {
                ContentView()
            } else {
                NavigationStack {
                    LoginView()
                }
            }
        }
    }
}
