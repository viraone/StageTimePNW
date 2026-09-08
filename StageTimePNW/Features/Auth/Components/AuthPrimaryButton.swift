import SwiftUI

struct AuthPrimaryButton: View {
    let title: String
    let isBusy: Bool
    let accessibilityID: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isBusy {
                    ProgressView().tint(.white)
                } else {
                    HStack(spacing: 8) {
                        Text(title).font(.system(size: 17, weight: .medium))
                        Image(systemName: "arrow.right").font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AuthTheme.Metrics.fieldVerticalPadding)
        }
        .background(AuthTheme.primaryGradient)
        .cornerRadius(AuthTheme.Metrics.fieldCornerRadius)
        .shadow(color: AuthTheme.Palette.accentDeep.opacity(0.4), radius: 10, x: 0, y: 5)
        .disabled(isBusy)
        .accessibilityLabel(title)
        .accessibilityValue(isBusy ? "Loading" : "")
        .accessibilityIdentifier(accessibilityID)
    }
}
