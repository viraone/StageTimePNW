import SwiftUI

struct ExploreView: View {
    var body: some View {
        ZStack {
            Color.pnwDarkBg.ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundColor(.pnwGreen)
                
                Text("Explore")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Search and discover open mics, comedians, and venues")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}
