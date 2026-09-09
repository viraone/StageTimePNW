import SwiftUI

// MARK: - TAB 2: Open Mic Map (Dynamic Directory)
struct OpenMicMapView: View {
    @ObservedObject var viewModel: OpenMicViewModel
    @State private var selectedDay: Weekday = Weekday.today
    @State private var selectedFilter: MicFilter = .all
    @State private var userSelectedMicID: String?
    @State private var showDistance: Bool = false
    @State private var tripIntelMic: OpenMic? = nil
    @StateObject private var locationService = LocationService()
    @ObservedObject private var barkMC = BarkMCService.shared

    /// The actual calendar date of the selected day tab (today or next occurrence).
    private var selectedDayDate: Date {
        let todayIndex = Calendar.current.component(.weekday, from: Date()) - 1
        guard let targetIndex = Weekday.allCases.firstIndex(of: selectedDay) else { return Date() }
        let offset = (targetIndex - todayIndex + 7) % 7
        return Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
    }

    /// Live MC host override (Tacoma Comedy downtown pulls its MC from
    /// Bark Entertainment's monthly list via OCR).
    private func hostOverride(for mic: OpenMic) -> String? {
        guard mic.id == BarkMCService.tacomaDowntownMicID else { return nil }
        return barkMC.mc(for: selectedDayDate)
    }

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
                        ScrollViewReader { proxy in
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
                                            onDirections: showDistance ? { tripIntelMic = mic } : nil,
                                            hostOverride: hostOverride(for: mic)
                                        )
                                        .id(mic.id)
                                        .onAppear {
                                            if mic.id == BarkMCService.tacomaDowntownMicID {
                                                barkMC.fetchMC(for: selectedDayDate)
                                            }
                                        }
                                        .onTapGesture {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                userSelectedMicID = mic.id
                                            }
                                        }
                                    }

                                    // Day summary board (like the website's Selected Day panel)
                                    DaySummaryCard(
                                        day: selectedDay,
                                        mics: micsForDay,
                                        nextUpID: nextUpMicID(in: micsForDay)
                                    ) { mic in
                                        withAnimation(.easeInOut(duration: 0.35)) {
                                            userSelectedMicID = mic.id
                                            proxy.scrollTo(mic.id, anchor: .top)
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
