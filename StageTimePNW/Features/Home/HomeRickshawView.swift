import SwiftUI

// MARK: - TAB 1: Home Screen (Rickshaw Signup)
struct HomeRickshawView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var viewModel: OpenMicViewModel

    @State private var stageName: String = ""
    @State private var instagram: String = ""
    @State private var performedBefore: Bool = false
    @State private var noShowAgreement: Bool = false
    @State private var guaranteeAgreement: Bool = false

    var body: some View {
        ZStack {
            Color.pnwDarkBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    
                    // Content: Check signup status and decide what Home should show
                                        if viewModel.isCheckingSignup {

                                            ProgressView()
                                                .tint(.pnwGreen)
                                                .padding(.top, 30)

                                        } else if viewModel.hasActiveSignup {

                                            RickshawInfoView()

                                        } else {

                                            // RICKSHAW HEADER (Shown ONLY on Request Form)
                                            VStack(spacing: 8) {
                                                Text("EVERY FRIDAY NIGHT")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.pnwRedText)
                                                    .tracking(2)

                                                Text("7PM - 9PM")
                                                    .font(.caption2)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.gray)

                                                Image("RickshawLogo")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(height: 90)
                                                    .padding(.vertical, 4)

                                                Text("Submit request for Read The Room. Spots are linked directly to your account.")
                                                    .font(.subheadline)
                                                    .foregroundColor(.white.opacity(0.8))
                                                    .multilineTextAlignment(.center)
                                                    .padding(.horizontal)
                                            }

                                            signupFormCard
                                        }
                }
                .padding(.bottom, 30)
            }
            if viewModel.showSubmissionToast {

                VStack(spacing: 12) {

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.pnwGreen)

                    Text("Thank you for requesting a spot this Friday!")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Status: Pending")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.pnwGreen)

                    Text("We'll let you know if you made it onto the lineup.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .frame(maxWidth: 320)
                .background(Color.pnwCardBg)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.pnwCardBorder, lineWidth: 1)
                )
                .shadow(radius: 20)
                .transition(.scale.combined(with: .opacity))
                .zIndex(10)
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.checkActiveSignup(for: authManager.currentUser)
        }
    }


    private var signupFormCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // 1. Stage Name
            VStack(alignment: .leading, spacing: 6) {
                Text("Stage Name / Full Name *")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                TextField("Your name", text: $stageName)
                    .textFieldStyle(PNWTextFieldStyle())
            }

            // 2. Email Address (LOCKED)
            VStack(alignment: .leading, spacing: 6) {
                Text("Email Address * (Locked to your account)")
                    .font(.caption)
                    .foregroundColor(.gray)

                HStack {
                    Text(authManager.currentUser?.email ?? "")
                        .foregroundColor(.gray)
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.black.opacity(0.4))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 1))
            }

            // 3. Instagram Handle
            VStack(alignment: .leading, spacing: 6) {
                Text("Instagram Handle (optional)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                TextField("@handle", text: $instagram)
                    .textFieldStyle(PNWTextFieldStyle())
            }

            // 4. Performed Before
            Toggle(isOn: $performedBefore) {
                Text("Have you performed at this show in the past?")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .toggleStyle(SwitchToggleStyle(tint: .pnwGreen))

            Divider().background(Color.white.opacity(0.1))

            // 5. Agreements
            Toggle(isOn: $noShowAgreement) {
                Text("I understand that if I miss my spot without notifying the host, it may affect future bookings. *")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .toggleStyle(SwitchToggleStyle(tint: .pnwRedText))

            Toggle(isOn: $guaranteeAgreement) {
                Text("I understand that submission does not guarantee a spot. Notifications go out on Thursday. *")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .toggleStyle(SwitchToggleStyle(tint: .pnwRedText))

            if let error = viewModel.signupError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.pnwRedText)
            }

            // 6. Submit Button
            Button(action: submitSignup) {
                if viewModel.isSubmittingSignup {
                    ProgressView().tint(.white)
                } else {
                    Text("Submit Request")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(canSubmit ? Color.pnwRedText : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .disabled(!canSubmit || viewModel.isSubmittingSignup)
        }
        .padding(20)
        .background(Color.pnwCardBg)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.pnwCardBorder, lineWidth: 1))
        .padding(.horizontal)
    }

    private var canSubmit: Bool {
        !stageName.trimmingCharacters(in: .whitespaces).isEmpty &&
        noShowAgreement &&
        guaranteeAgreement
    }


    private func submitSignup() {
        Task {
            await viewModel.submitSignup(
                for: authManager.currentUser,
                stageName: stageName,
                instagram: instagram,
                performedBefore: performedBefore,
                noShowAgreement: noShowAgreement,
                guaranteeAgreement: guaranteeAgreement
            )
        }
    }
}
