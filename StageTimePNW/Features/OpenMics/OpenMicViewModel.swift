import Foundation
import SwiftUI
import Combine
import OSLog

@MainActor
final class OpenMicViewModel: ObservableObject {

    // MARK: - Directory

    @Published private(set) var allMics: [OpenMic] = []
    @Published private(set) var isLoading = false
    @Published private(set) var loadError: String?

    // MARK: - Rickshaw signup

    @Published private(set) var hasActiveSignup = false
    @Published private(set) var isCheckingSignup = false
    @Published private(set) var isSubmittingSignup = false
    @Published private(set) var signupError: String?
    @Published private(set) var showSubmissionToast = false

    private let micRepository: OpenMicRepository
    private let signupRepository: SignupRepository
    private let toastDuration: Duration

    init(
        micRepository: OpenMicRepository = RemoteOpenMicRepository(),
        signupRepository: SignupRepository = SupabaseSignupRepository(),
        toastDuration: Duration = .seconds(3),
        loadOnInit: Bool = true
    ) {
        self.micRepository = micRepository
        self.signupRepository = signupRepository
        self.toastDuration = toastDuration
        if loadOnInit {
            Task { await fetchMics() }
        }
    }

    // MARK: - Directory

    func fetchMics() async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        do {
            allMics = try await micRepository.fetchMics()
        } catch {
            loadError = error.localizedDescription
            Log.openMics.error("Failed to fetch open mics: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Mics active on `day`, ordered by start time.
    func mics(for day: Weekday) -> [OpenMic] {
        allMics
            .filter { $0.isActive(on: day) }
            .sorted { $0.startMinutesFromMidnight < $1.startMinutesFromMidnight }
    }

    // MARK: - Signup

    func checkActiveSignup(for user: AuthUser?) async {
        guard let user else {
            hasActiveSignup = false
            return
        }
        isCheckingSignup = true
        defer { isCheckingSignup = false }

        do {
            hasActiveSignup = try await signupRepository.hasActiveSignup(userID: user.id)
        } catch {
            // Never assume the user has already submitted if the lookup fails.
            hasActiveSignup = false
            Log.openMics.error("Signup lookup failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Submits a slot request for `user`. Returns true on success.
    @discardableResult
    func submitSignup(
        for user: AuthUser?,
        stageName: String,
        instagram: String,
        performedBefore: Bool,
        noShowAgreement: Bool,
        guaranteeAgreement: Bool
    ) async -> Bool {
        guard let user, let email = user.email else {
            signupError = RepositoryError.notAuthenticated.errorDescription
            return false
        }
        isSubmittingSignup = true
        signupError = nil
        defer { isSubmittingSignup = false }

        let request = SignupRequest(
            name: stageName.trimmingCharacters(in: .whitespaces),
            email: email,
            instagram: instagram,
            performedBefore: performedBefore,
            noShowAgreement: noShowAgreement,
            guaranteeAgreement: guaranteeAgreement,
            isVerified: true, // signed-in app users are auto-verified
            authUserID: user.id
        )

        do {
            try await signupRepository.submit(request)
            hasActiveSignup = true
            Task { await showSuccessfulSubmissionToast() }
            return true
        } catch {
            signupError = error.localizedDescription
            Log.openMics.error("Signup submit failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func showSuccessfulSubmissionToast() async {
        withAnimation(.easeInOut(duration: 0.25)) { showSubmissionToast = true }
        try? await Task.sleep(for: toastDuration)
        withAnimation(.easeInOut(duration: 0.25)) { showSubmissionToast = false }
    }
}
