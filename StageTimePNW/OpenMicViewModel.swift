import Foundation
import SwiftUI
import Combine
import Supabase

@MainActor
class OpenMicViewModel: ObservableObject {

    // MARK: - Existing Open Mic Data

    @Published var allMics: [OpenMic] = []
    @Published var isLoading: Bool = false

    // MARK: - Rickshaw Signup State

    @Published var hasActiveSignup: Bool = false
    @Published var isCheckingSignup: Bool = false

    // We'll use this later for the 3-second confirmation popup.
    @Published var showSubmissionToast: Bool = false

    private let jsonURL = URL(
        string: "https://stagetimepnw.com/data/open-mics.json"
    )!

    init() {
        Task {
            await fetchMics()
        }
    }

    // MARK: - Fetch Open Mic Directory

    func fetchMics() async {

        isLoading = true

        do {

            let (data, response) = try await URLSession.shared.data(
                from: jsonURL
            )

            guard
                let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200
            else {
                isLoading = false
                return
            }

            let decoder = JSONDecoder()

            self.allMics = try decoder.decode(
                [OpenMic].self,
                from: data
            )

        } catch {

            print("Failed to fetch live JSON: \(error)")
        }

        isLoading = false
    }

    // MARK: - Filter Mics by Day (Sorted Chronologically)

        func mics(for day: Weekday) -> [OpenMic] {

            allMics
                .filter { $0.isActive(on: day) }
                .sorted { $0.startMinutesFromMidnight < $1.startMinutesFromMidnight }
        }

    // MARK: - Check Current User's Rickshaw Signup

    func checkActiveSignup() async {

        isCheckingSignup = true

        defer {
            isCheckingSignup = false
        }

        do {

            // Get the currently logged-in Supabase user.
            let session = try await supabase.auth.session
            let userID = session.user.id

            // Query public.signups for a row attached
            // to this authenticated user's UUID.
            let response: [SignupLookupRow] = try await supabase
                .from("signups")
                .select("id")
                .eq("auth_user_id", value: userID.uuidString)
                .limit(1)
                .execute()
                .value

            // If we found at least one row,
            // this user already has an active request.
            hasActiveSignup = !response.isEmpty

        } catch {

            print("Failed to check active signup: \(error)")

            // If the query fails, do NOT assume the user
            // has submitted.
            hasActiveSignup = false
        }
    }

    // MARK: - Called After Successful Request Submission

    func markSignupSubmitted() {

        hasActiveSignup = true
    }

    
    // MARK: - Show 3-Second Submission Toast

    func showSuccessfulSubmissionToast() async {

        withAnimation(.easeInOut(duration: 0.25)) {
            showSubmissionToast = true
        }

        try? await Task.sleep(
            for: .seconds(3)
        )

        withAnimation(.easeInOut(duration: 0.25)) {
            showSubmissionToast = false
        }
    }
}

// MARK: - Minimal Signup Lookup Model

private struct SignupLookupRow: Decodable {

    let id: Int
}
