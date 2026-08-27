import SwiftUI
import Supabase

// MARK: - App Colors
extension Color {
    static let pnwGreen = Color(red: 0.20, green: 0.85, blue: 0.35)
    static let pnwDarkBg = Color(red: 0.05, green: 0.05, blue: 0.05)
    static let pnwCardBg = Color(red: 0.09, green: 0.09, blue: 0.09)
    static let pnwCardBorder = Color.white.opacity(0.12)
    static let pnwRedText = Color(red: 1.0, green: 0.35, blue: 0.35)
}

// MARK: - Enums
enum Weekday: String, CaseIterable, Identifiable {
    case sun = "Sun", mon = "Mon", tue = "Tue", wed = "Wed", thu = "Thu", fri = "Fri", sat = "Sat"
    var id: String { rawValue }

    /// Today's weekday, e.g. .thu on a Thursday.
    static var today: Weekday {
        // Calendar weekday: 1 = Sunday ... 7 = Saturday
        let index = Calendar.current.component(.weekday, from: Date()) - 1
        return Weekday.allCases[index]
    }
}

enum AppTab {
    case home
    case map
}

// MARK: - Main Content View
struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab: AppTab = .home
    @StateObject private var micViewModel = OpenMicViewModel()

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.pnwDarkBg)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // TAB 1: HOME (Rickshaw Signup with locked email)
            NavigationStack {
                HomeRickshawView(viewModel: micViewModel)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(AppTab.home)

            // TAB 2: OPEN MIC MAP (Dynamic directory - NO Rickshaw logo)
            NavigationStack {
                OpenMicMapView(viewModel: micViewModel)
            }
            .tabItem {
                Label("Open Mic Map", systemImage: "map.fill")
            }
            .tag(AppTab.map)
        }
        .accentColor(.pnwRedText)
    }
}

// MARK: - TAB 1: Home Screen (Rickshaw Signup)
struct HomeRickshawView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var viewModel: OpenMicViewModel

    @State private var stageName: String = ""
    @State private var instagram: String = ""
    @State private var performedBefore: Bool = false
    @State private var noShowAgreement: Bool = false
    @State private var guaranteeAgreement: Bool = false
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil

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

                                            // Top Bar: Sign out button
                                            HStack {
                                                Spacer()
                                                Button(action: { Task { await authManager.signOut() } }) {
                                                    Text("Sign Out")
                                                        .font(.caption)
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                            .padding(.horizontal)

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
            await viewModel.checkActiveSignup()
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

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.pnwRedText)
            }

            // 6. Submit Button
            Button(action: submitSignup) {
                if isSubmitting {
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
            .disabled(!canSubmit || isSubmitting)
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

  

    // Submit signup directly as verified
    private func submitSignup() {
        guard let user = authManager.currentUser, let email = user.email else { return }
        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                struct NewSignup: Encodable {
                    let name: String
                    let email: String
                    let instagram: String
                    let performed_before: Bool
                    let no_show_agreement: Bool
                    let guarantee_agreement: Bool
                    let is_verified: Bool
                    let auth_user_id: UUID
                }

                let payload = NewSignup(
                    name: stageName,
                    email: email,
                    instagram: instagram,
                    performed_before: performedBefore,
                    no_show_agreement: noShowAgreement,
                    guarantee_agreement: guaranteeAgreement,
                    is_verified: true, // Auto-verified for logged in app users
                    auth_user_id: user.id
                )

                try await supabase
                    .from("signups")
                    .insert(payload)
                    .execute()

                viewModel.markSignupSubmitted()

                Task {
                    await viewModel.showSuccessfulSubmissionToast()
                }
            } catch {
                self.errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}

// MARK: - TAB 2: Open Mic Map (Dynamic Directory)
struct OpenMicMapView: View {
    @ObservedObject var viewModel: OpenMicViewModel
    @State private var selectedDay: Weekday = Weekday.today
    @State private var userSelectedMicID: String?

    /// Minutes from midnight right now, used to find the next upcoming mic.
    private var nowMinutes: Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: Date())
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }

    /// The mic starting closest in time (soonest upcoming) for the selected day.
    /// On today's list, the first mic that hasn't started yet; otherwise the
    /// earliest mic of the day.
    private func nextUpMicID(in mics: [OpenMic]) -> String? {
        guard !mics.isEmpty else { return nil }
        if selectedDay == Weekday.today,
           let upcoming = mics.first(where: { $0.startMinutesFromMidnight >= nowMinutes }) {
            return upcoming.id
        }
        return mics.first?.id
    }

    var body: some View {
        ZStack {
            Color.pnwDarkBg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                // Header (NO RICKSHAW LOGO)
                VStack(alignment: .leading, spacing: 4) {
                    Text("OPEN MICS TODAY")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.pnwGreen)
                        .tracking(1)

                    Text(selectedDay.rawValue.uppercased())
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                }
                .padding(.horizontal)
                .padding(.top, 10)

                // Day Selector Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Weekday.allCases) { day in
                            Button(action: {
                                selectedDay = day
                                userSelectedMicID = nil
                            }) {
                                Text(day.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedDay == day ? Color.pnwGreen : Color.pnwCardBg)
                                    .foregroundColor(selectedDay == day ? .black : .white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Dynamic Mics List
                if viewModel.isLoading {
                    Spacer()
                    ProgressView().tint(.pnwGreen).frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    let micsForDay = viewModel.mics(for: selectedDay)
                    if micsForDay.isEmpty {
                        Spacer()
                        Text("No open mics listed for \(selectedDay.rawValue).")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        let highlightedID = userSelectedMicID ?? nextUpMicID(in: micsForDay)
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(micsForDay) { mic in
                                    DynamicMicCard(
                                        mic: mic,
                                        isHighlighted: mic.id == highlightedID,
                                        isNextUp: mic.id == nextUpMicID(in: micsForDay)
                                    )
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            userSelectedMicID = mic.id
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .refreshable {
            await viewModel.fetchMics()
        }
    }
}

// MARK: - Dynamic Card View
struct DynamicMicCard: View {
    let mic: OpenMic
    var isHighlighted: Bool = false
    var isNextUp: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isNextUp {
                Label("UP NEXT", systemImage: "clock.fill")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.pnwGreen)
                    .cornerRadius(4)
            }

            HStack {
                Text(mic.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                if let rec = mic.recurrenceText {
                    Text(rec)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.pnwGreen)
                }
            }

            if let signup = mic.timeSignupStart, !signup.isEmpty {
                Text("Signup: \(signup)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Text(mic.location)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))

            if let type = mic.openMicType, !type.isEmpty {
                Text(type)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.pnwRedText.opacity(0.2))
                    .foregroundColor(.pnwRedText)
                    .cornerRadius(4)
            }

            if let info = mic.requirementsInfo, !info.isEmpty {
                Text(info)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.top, 2)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isHighlighted ? Color.pnwGreen.opacity(0.12) : Color.pnwCardBg)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isHighlighted ? Color.pnwGreen : Color.pnwCardBorder,
                    lineWidth: isHighlighted ? 2 : 1
                )
        )
        .shadow(color: isHighlighted ? Color.pnwGreen.opacity(0.35) : .clear, radius: 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Custom Style Helper
struct PNWTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.black.opacity(0.4))
            .foregroundColor(.white)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 1))
    }
}
