import Foundation

struct UserProfile: Equatable {
    let uid: String
    let email: String
    let createdAt: Date?
    let firstName: String?
    let monthlyIncome: Int
    let monthlySavingsGoal: Int
    let onboardingComplete: Bool
    let isPremium: Bool
    let subscriptionPlan: SubscriptionPlan?
    let subscriptionStatus: String?
    let trialDays: Int?
    let trialStartedAt: Date?
    let isFoundingMember: Bool
    let foundingMemberNumber: Int?
    let lockedAnnualPriceCents: Int?
    let lockedAnnualPriceCurrency: String?
    let hasEarlySupporterBadge: Bool
    let futurePremiumFeaturesIncluded: Bool
}
