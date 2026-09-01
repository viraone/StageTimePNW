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

enum MicFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case comedyOnly = "Comedy Only"
    case mix = "Mix Mic"
    
    var id: String { rawValue }
}

enum AppTab {
    case home
    case explore
    case add
    case tonight
    case profile
}

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

// MARK: - Custom Bottom Tab Bar (Instagram Style)
struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    
    var body: some View {
        HStack(spacing: 0) {
            // Home Tab
            TabBarButton(
                icon: "house",
                filledIcon: "house.fill",
                label: "Home",
                isSelected: selectedTab == .home
            ) {
                selectedTab = .home
            }
            
            // Add/Create Tab (Signup for your app)
            TabBarButton(
                icon: "mic",
                filledIcon: "mic.fill",
                label: "Sign Up",
                isSelected: selectedTab == .add,
                accentColor: Color(red: 1.0, green: 0.35, blue: 0.35)
            ) {
                selectedTab = .add
            }
            
            // Tonight List Tab (Friday Rickshaw lineup)
            TabBarButton(
                icon: "list.star",
                filledIcon: "list.star",
                label: "Tonight List",
                isSelected: selectedTab == .tonight
            ) {
                selectedTab = .tonight
            }
            
            // Explore/Search Tab
            TabBarButton(
                icon: "magnifyingglass",
                filledIcon: "magnifyingglass",
                label: "Search",
                isSelected: selectedTab == .explore
            ) {
                selectedTab = .explore
            }
            
            // Profile Tab
            TabBarButton(
                icon: "person.circle",
                filledIcon: "person.circle.fill",
                label: "Profile",
                isSelected: selectedTab == .profile
            ) {
                selectedTab = .profile
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            Color.black
                .overlay(
                    // Subtle top border
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 0.5),
                    alignment: .top
                )
        )
    }
}

// MARK: - Tab Bar Button (Instagram Style)
struct TabBarButton: View {
    let icon: String
    let filledIcon: String
    var label: String? = nil
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
            VStack(spacing: 3) {
                Image(systemName: isSelected ? filledIcon : icon)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(isSelected ? (accentColor ?? .white) : .gray)
                    .frame(height: 26)
                
                if let label {
                    Text(label)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(isSelected ? (accentColor ?? .white) : .gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
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
    @State private var selectedFilter: MicFilter = .all
    @State private var userSelectedMicID: String?
    @State private var showDistance: Bool = false
    @State private var tripIntelMic: OpenMic? = nil
    @StateObject private var locationService = LocationService()

    /// Minutes from midnight right now, used to find the next upcoming mic.
    private var nowMinutes: Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: Date())
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }

    /// The mic starting closest in time (soonest upcoming) for the selected day.
    /// On today's list, the first mic that hasn't started yet — if every mic
    /// today already started, nothing is "next". On other days, the earliest
    /// mic of that day.
    private func nextUpMicID(in mics: [OpenMic]) -> String? {
        guard !mics.isEmpty else { return nil }
        if selectedDay == Weekday.today {
            return mics.first(where: { $0.startMinutesFromMidnight >= nowMinutes })?.id
        }
        return mics.first?.id
    }
    
    /// Filter mics based on selected filter
    private func filteredMics(_ mics: [OpenMic]) -> [OpenMic] {
        switch selectedFilter {
        case .all:
            return mics
        case .comedyOnly:
            return mics.filter { mic in
                guard let type = mic.openMicType?.lowercased() else { return false }
                // Only pure "Comedy" - not mix mics
                return type == "comedy" || type == "only comedy"
            }
        case .mix:
            return mics.filter { mic in
                guard let type = mic.openMicType?.lowercased() else { return false }
                // Mix mics contain words like "mix", "variety", "music", etc.
                return type.contains("mix") || 
                       type.contains("variety") || 
                       type.contains("music") ||
                       type.contains("anything")
            }
        }
    }
    
    // Format current date
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: Date()).uppercased()
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header with date
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .lastTextBaseline) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("OPEN MICS TODAY")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(red: 0.05, green: 0.82, blue: 0.45))
                                .tracking(1.5)

                            Text(formattedDate)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        
                        Spacer(minLength: 12)
                        
                        // Show Distance Button
                        Button(action: {
                            showDistance.toggle()
                            if showDistance { locationService.request() }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: showDistance ? "location.fill" : "location")
                                    .font(.system(size: 14))
                                Text("Show Distance")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(red: 0.05, green: 0.82, blue: 0.45))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }

                // Day Selector Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Weekday.allCases) { day in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedDay = day
                                    userSelectedMicID = nil
                                }
                            }) {
                                Text(day.rawValue)
                                    .font(.system(size: 15, weight: .semibold))
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 10)
                                    .background(selectedDay == day ? Color(red: 0.05, green: 0.82, blue: 0.45) : Color(white: 0.12))
                                    .foregroundColor(selectedDay == day ? .black : .white)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(selectedDay == day ? 0 : 0.1), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                
                // Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(MicFilter.allCases) { filter in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFilter = filter
                                    userSelectedMicID = nil
                                }
                            }) {
                                Text(filter.rawValue)
                                    .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selectedFilter == filter ? Color(red: 1.0, green: 0.35, blue: 0.35) : Color(white: 0.12))
                                .foregroundColor(selectedFilter == filter ? .white : .gray)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(selectedFilter == filter ? 0 : 0.1), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
                
                // Location note
                if showDistance && locationService.isDenied {
                    Text("Location access is off. Enable it in Settings → StageTimePNW to see distances.")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 1.0, green: 0.35, blue: 0.35))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                } else if !showDistance {
                    Text("Tap Show Distance to see drive times and directions.")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                }

                // Dynamic Mics List
                if viewModel.isLoading {
                    Spacer()
                    ProgressView().tint(Color(red: 0.05, green: 0.82, blue: 0.45)).frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    let micsForDay = filteredMics(viewModel.mics(for: selectedDay))
                    if micsForDay.isEmpty {
                        Spacer()
                        VStack(spacing: 8) {
                            Text("No mics found")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Try a different filter or day")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        let highlightedID = userSelectedMicID ?? nextUpMicID(in: micsForDay)
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(micsForDay) { mic in
                                    DynamicMicCard(
                                        mic: mic,
                                        isHighlighted: mic.id == highlightedID,
                                        isNextUp: mic.id == nextUpMicID(in: micsForDay),
                                        distanceMiles: showDistance
                                            ? locationService.location.flatMap { TripMath.miles(from: $0, to: mic) }
                                            : nil,
                                        onDirections: showDistance ? { tripIntelMic = mic } : nil
                                    )
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            userSelectedMicID = mic.id
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .refreshable {
            await viewModel.fetchMics()
        }
        .sheet(item: $tripIntelMic) { mic in
            TripIntelSheet(mic: mic, userLocation: locationService.location)
        }
    }
}

// MARK: - Dynamic Card View
struct DynamicMicCard: View {
    let mic: OpenMic
    var isHighlighted: Bool = false
    var isNextUp: Bool = false
    var distanceMiles: Double? = nil
    var onDirections: (() -> Void)? = nil
    
    @State private var isPressed: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Badges Row - Only show "NEXT OPEN MIC" badge
            if isNextUp {
                HStack(spacing: 8) {
                    Text("NEXT OPEN MIC")
                        .font(.system(size: 10, weight: .black))
                        .tracking(0.5)
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.05, green: 0.82, blue: 0.45))
                        .cornerRadius(4)
                    
                    Spacer()
                }
                .padding(.bottom, 12)
            }

            // Main Content
            VStack(alignment: .leading, spacing: 12) {
                // Title and Time
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mic.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        if let rec = mic.recurrenceText {
                            Text(rec.uppercased())
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.gray)
                                .tracking(0.5)
                        }
                    }
                    
                    Spacer()
                    
                    // Time display (show start time if available)
                    if let startTime = mic.displayStartTime {
                        Text(startTime)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                // Signup and Start times
                if let displayStart = mic.displayStartTime {
                    HStack(spacing: 4) {
                        Text("Start")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.gray)
                        Text(displayStart)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                
                if let displaySignup = mic.displaySignupTime {
                    HStack(spacing: 4) {
                        Text("Signup")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.gray)
                        Text(displaySignup)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                
                // Location
                Text(mic.location)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))

                // Distance + Directions (shown when Show Distance is on)
                if let distanceMiles {
                    HStack(spacing: 10) {
                        HStack(spacing: 5) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 11))
                            Text("\(String(format: "%.1f", distanceMiles)) mi · ~\(TripMath.driveMinutes(forMiles: distanceMiles)) min drive")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(Color(red: 0.05, green: 0.82, blue: 0.45))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.05, green: 0.82, blue: 0.45).opacity(0.12))
                        .cornerRadius(6)

                        Spacer()

                        if onDirections != nil {
                            Button(action: { onDirections?() }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                        .font(.system(size: 11))
                                    Text("Directions & Transit")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundColor(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Color(red: 0.05, green: 0.82, blue: 0.45))
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 2)
                }
                
                // Tags
                HStack(spacing: 8) {
                    if let type = mic.openMicType, !type.isEmpty {
                        Text(type.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.5)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color(white: 0.2))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    
                    // Price tag from actual data
                    if let price = mic.priceForTime, !price.isEmpty {
                        Text(price.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.5)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color(white: 0.2))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    
                    // Age requirement
                    if let age = mic.ageRequirement, !age.isEmpty {
                        Text(age.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.5)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color(white: 0.2))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                
                // Details & Rules Section
                if let info = mic.requirementsInfo, !info.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DETAILS & RULES")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.gray)
                            .tracking(0.5)
                        
                        Text(info)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                            .lineSpacing(2)
                    }
                    .padding(.top, 4)
                }
                
                // Signup details button (if web signup or signup details exist)
                if (mic.webSignup != nil && !mic.webSignup!.isEmpty) || (mic.signupDetails != nil && !mic.signupDetails!.isEmpty) {
                    Button(action: {
                        // Open signup URL if available
                        if let urlString = mic.webSignup, !urlString.isEmpty, let url = URL(string: urlString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("Signup details")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(white: 0.15))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isHighlighted 
                ? Color(red: 0.05, green: 0.82, blue: 0.45).opacity(0.08)
                : Color(white: 0.08)
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isHighlighted 
                        ? Color(red: 0.05, green: 0.82, blue: 0.45).opacity(0.5)
                        : Color.white.opacity(0.08),
                    lineWidth: isHighlighted ? 2 : 1
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .shadow(
            color: isHighlighted 
                ? Color(red: 0.05, green: 0.82, blue: 0.45).opacity(isPressed ? 0.4 : 0.2)
                : Color.black.opacity(isPressed ? 0.3 : 0),
            radius: isPressed ? 12 : 8,
            y: isPressed ? 6 : 4
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            if pressing {
                isPressed = true
                // Haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            } else {
                isPressed = false
            }
        }, perform: {})
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
// MARK: - Placeholder Views for New Tabs

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

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        ZStack {
            Color.pnwDarkBg.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 12) {
                        // Profile Picture Placeholder
                        Circle()
                            .fill(Color.pnwGreen)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.black)
                            )
                        
                        // Email
                        Text(authManager.currentUser?.email ?? "Unknown User")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        // Stats Row (Instagram style)
                        HStack(spacing: 40) {
                            VStack(spacing: 4) {
                                Text("12")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Signups")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(spacing: 4) {
                                Text("8")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Performed")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(spacing: 4) {
                                Text("5")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Venues")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.top, 40)
                    
                    // Edit Profile Button
                    Button(action: {}) {
                        Text("Edit Profile")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(white: 0.12))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 20)
                    
                    // Settings Options
                    VStack(spacing: 0) {
                        ProfileMenuItem(icon: "gear", title: "Settings")
                        ProfileMenuItem(icon: "clock.arrow.circlepath", title: "Your Activity")
                        ProfileMenuItem(icon: "bookmark", title: "Saved Mics")
                        ProfileMenuItem(icon: "list.bullet", title: "Signup History")
                    }
                    .background(Color.pnwCardBg)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.pnwCardBorder, lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    
                    // Sign Out Button
                    Button(action: { Task { await authManager.signOut() } }) {
                        Text("Sign Out")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.pnwRedText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(white: 0.12))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.pnwRedText.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

struct ProfileMenuItem: View {
    let icon: String
    let title: String
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

