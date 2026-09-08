import SwiftUI

struct NotificationsView: View {
    var body: some View {
        ZStack {
            Color.pnwDarkBg.ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.pnwGreen)
                
                Text("Notifications")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Get updates about your signups and upcoming shows")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}
