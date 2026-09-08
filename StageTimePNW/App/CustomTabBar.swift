import SwiftUI

// MARK: - Custom Bottom Tab Bar (Instagram Style)
struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    
    var body: some View {
        HStack(spacing: 6) {
            // Home Tab
            TabBarButton(
                icon: "house",
                filledIcon: "house.fill",
                isSelected: selectedTab == .home
            ) {
                selectedTab = .home
            }
            
            // Add/Create Tab (Signup for your app)
            TabBarButton(
                icon: "mic",
                filledIcon: "mic.fill",
                isSelected: selectedTab == .add,
                accentColor: Color(red: 1.0, green: 0.35, blue: 0.35)
            ) {
                selectedTab = .add
            }
            
            // Tonight List Tab (Friday Rickshaw lineup)
            TabBarButton(
                icon: "list.star",
                filledIcon: "list.star",
                isSelected: selectedTab == .tonight
            ) {
                selectedTab = .tonight
            }
            
            // Explore/Search Tab
            TabBarButton(
                icon: "magnifyingglass",
                filledIcon: "magnifyingglass",
                isSelected: selectedTab == .explore
            ) {
                selectedTab = .explore
            }
            
            // Profile Tab
            TabBarButton(
                icon: "person.circle",
                filledIcon: "person.circle.fill",
                isSelected: selectedTab == .profile
            ) {
                selectedTab = .profile
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color(white: 0.10).opacity(0.92))
                .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
                .shadow(color: .black.opacity(0.5), radius: 14, y: 6)
        )
        .padding(.horizontal, 40)
        .padding(.top, 6)
        .padding(.bottom, 2)
    }
}

// MARK: - Tab Bar Button (Instagram Style)

// MARK: - Tab Bar Button (Instagram Style)
struct TabBarButton: View {
    let icon: String
    let filledIcon: String
    var isSelected: Bool
    var accentColor: Color?
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            // Haptic feedback like Instagram
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            
            withAnimation(.easeInOut(duration: 0.2)) {
                action()
            }
        }) {
            Image(systemName: isSelected ? filledIcon : icon)
                .font(.system(size: 21, weight: .semibold))
                .foregroundColor(isSelected ? (accentColor ?? .white) : Color(white: 0.65))
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(isSelected ? Color(white: 0.24) : Color.clear)
                )
        }
        .frame(maxWidth: .infinity)
    }
}
