import Foundation
import Supabase

/// A performer's request for a Rickshaw open-mic slot.
struct SignupRequest: Encodable, Equatable, Sendable {
    let name: String
    let email: String
    let instagram: String
    let performedBefore: Bool
    let noShowAgreement: Bool
    let guaranteeAgreement: Bool
    let isVerified: Bool
    let authUserID: UUID

    enum CodingKeys: String, CodingKey {
        case name, email, instagram
        case performedBefore = "performed_before"
        case noShowAgreement = "no_show_agreement"
        case guaranteeAgreement = "guarantee_agreement"
        case isVerified = "is_verified"
        case authUserID = "auth_user_id"
    }
}

protocol SignupRepository: Sendable {
    func hasActiveSignup(userID: UUID) async throws -> Bool
    func submit(_ request: SignupRequest) async throws
}

struct SupabaseSignupRepository: SignupRepository {
    private let client: SupabaseClient

    init(client: SupabaseClient = supabase) {
        self.client = client
    }

    func hasActiveSignup(userID: UUID) async throws -> Bool {
        struct Row: Decodable { let id: Int }
        let rows: [Row] = try await client
            .from("signups")
            .select("id")
            .eq("auth_user_id", value: userID.uuidString)
            .limit(1)
            .execute()
            .value
        return !rows.isEmpty
    }

    func submit(_ request: SignupRequest) async throws {
        try await client.from("signups").insert(request).execute()
    }
}
