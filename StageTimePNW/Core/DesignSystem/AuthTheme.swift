import SwiftUI

/// Design tokens for the authentication surfaces.
enum AuthTheme {
    enum Palette {
        static let skySoft = Color(red: 0.35, green: 0.45, blue: 0.65)
        static let skyMedium = Color(red: 0.25, green: 0.35, blue: 0.55)
        static let navyDeep = Color(red: 0.15, green: 0.20, blue: 0.40)
        static let navyDark = Color(red: 0.12, green: 0.15, blue: 0.30)
        static let accent = Color(red: 0.50, green: 0.60, blue: 0.80)
        static let accentDeep = Color(red: 0.40, green: 0.50, blue: 0.70)
    }

    enum Metrics {
        static let fieldCornerRadius: CGFloat = 14
        static let cardCornerRadius: CGFloat = 24
        static let bannerCornerRadius: CGFloat = 12
        static let fieldVerticalPadding: CGFloat = 18
        static let fieldHorizontalPadding: CGFloat = 20
        static let iconColumnWidth: CGFloat = 20
    }

    static let primaryGradient = LinearGradient(
        colors: [Palette.accent, Palette.accentDeep],
        startPoint: .leading,
        endPoint: .trailing
    )
}

/// Full-bleed gradient backdrop shared by the sign-in and sign-up screens.
struct AuthBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AuthTheme.Palette.skySoft,
                    AuthTheme.Palette.skyMedium,
                    AuthTheme.Palette.navyDeep,
                    AuthTheme.Palette.navyDark,
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [Color.white.opacity(0.08), .clear],
                center: .top,
                startRadius: 50,
                endRadius: 500
            )
            Color.black.opacity(0.15)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct AuthFieldChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, AuthTheme.Metrics.fieldHorizontalPadding)
            .padding(.vertical, AuthTheme.Metrics.fieldVerticalPadding)
            .background(
                RoundedRectangle(cornerRadius: AuthTheme.Metrics.fieldCornerRadius)
                    .fill(Color.white.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: AuthTheme.Metrics.fieldCornerRadius)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
    }
}

extension View {
    func authFieldChrome() -> some View { modifier(AuthFieldChrome()) }
}
