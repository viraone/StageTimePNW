import SwiftUI

/// Inline success / error banner. Exposed to accessibility as a single element
/// so automation and VoiceOver read the message, not the icon.
struct AuthStatusBanner: View {
    enum Style {
        case success, error

        var systemImage: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            }
        }

        var tint: Color {
            switch self {
            case .success: return AuthTheme.Palette.accent
            case .error: return .red
            }
        }
    }

    let style: Style
    let message: String
    let accessibilityID: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: style.systemImage)
                .font(.system(size: 14))
                .foregroundColor(style.tint.opacity(0.9))
            Text(message)
                .font(.system(size: 13, weight: style == .success ? .medium : .regular))
                .foregroundColor(style == .success ? .white.opacity(0.95) : style.tint.opacity(0.95))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AuthTheme.Metrics.bannerCornerRadius)
                .fill(style.tint.opacity(style == .success ? 0.15 : 0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: AuthTheme.Metrics.bannerCornerRadius)
                        .stroke(style.tint.opacity(0.3), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
        .accessibilityIdentifier(accessibilityID)
        .accessibilityAddTraits(style == .error ? .isStaticText : [])
    }
}
