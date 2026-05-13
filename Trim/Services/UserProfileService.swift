import Foundation
import FirebaseAuth

final class UserProfileService {
    static let shared = UserProfileService()
        
    init() {}
    
    func createUserProfileIfNeeded(user: User, firstName: String? = nil) async throws {
        if let firstName {
            let cleaned = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleaned.isEmpty {
                _ = try await TrimApiService.shared.updateUserProfile(
                    firstName: cleaned,
                    monthlyIncome: nil,
                    monthlySavingsGoal: nil,
                    onboardingComplete: nil
                )
                return
            }
        }
        _ = try await TrimApiService.shared.fetchUserProfile()
    }

    func fetchUserProfile(uid: String) async throws -> UserProfile {
        _ = uid
        return try await TrimApiService.shared.fetchUserProfile()
    }
    
    func markOnboardingComplete(uid: String) async throws {
        _ = uid
        _ = try await TrimApiService.shared.updateUserProfile(
            firstName: nil,
            monthlyIncome: nil,
            monthlySavingsGoal: nil,
            onboardingComplete: true
        )
    }
    
    func updateOnboardingInputs(uid: String, firstName: String?, monthlyIncome: Int, monthlySavingsGoal: Int) async throws {
        _ = uid
        let cleaned = firstName?.trimmingCharacters(in: .whitespacesAndNewlines)
        _ = try await TrimApiService.shared.updateUserProfile(
            firstName: (cleaned?.isEmpty == false) ? cleaned : nil,
            monthlyIncome: monthlyIncome,
            monthlySavingsGoal: monthlySavingsGoal,
            onboardingComplete: true
        )
    }
    
    func fetchFoundingAnnualOfferState() async throws -> FoundingAnnualOfferState {
        return try await TrimApiService.shared.fetchFoundingAnnualOfferState()
    }
    
    func startPremiumTrial(uid: String, plan: SubscriptionPlan, trialDays: Int, annualPriceCents: Int, annualCurrency: String) async throws {
        _ = uid
        _ = try await TrimApiService.shared.startPremiumTrial(
            plan: plan,
            trialDays: trialDays,
            annualPriceCents: annualPriceCents,
            annualCurrency: annualCurrency
        )
    }
}
