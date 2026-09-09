import SwiftUI

// MARK: - Main Content View
struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab: AppTab = .home
    @StateObject private var micViewModel = OpenMicViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Content Area
                Group {
                    switch selectedTab {
                    case .home:
                        OpenMicMapView(viewModel: micViewModel)
                    case .explore:
                        ExploreView()
                    case .add:
                        HomeRickshawView(viewModel: micViewModel)
                    case .tonight:
                        TonightListView()
                    case .profile:
                        ProfileView()
                    }
                }
                
                // Custom Bottom Tab Bar
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
    }
}
