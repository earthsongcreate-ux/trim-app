import Foundation
import FirebaseAuth
import FirebaseFirestore

final class UserProfileService {
    static let shared = UserProfileService()
    
    private let db: Firestore
    
    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }
    
    private let foundingAnnualOfferRefPath: (collection: String, document: String) = ("app_meta", "founding_annual_offer")
    private let defaultFoundingAnnualLimit: Int = 250
    
    func createUserProfileIfNeeded(user: User, firstName: String? = nil) async throws {
        let uid = user.uid
        let email = user.email ?? ""
        
        let docRef = db.collection("users").document(uid)
        
        try await runTransaction { transaction in
            let snapshot = try transaction.getDocument(docRef)
            if snapshot.exists {
                return
            }
            
            var data: [String: Any] = [
                "uid": uid,
                "email": email,
                "createdAt": FieldValue.serverTimestamp(),
                "monthlyIncome": 0,
                "monthlySavingsGoal": 0,
                "onboardingComplete": false,
                "isPremium": false,
                "isFoundingMember": false,
                "hasEarlySupporterBadge": false,
                "futurePremiumFeaturesIncluded": false
            ]
            
            if let firstName, !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                data["firstName"] = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            transaction.setData(data, forDocument: docRef, merge: false)
            return
        }
    }

    func fetchUserProfile(uid: String) async throws -> UserProfile {
        let snapshot = try await db.collection("users").document(uid).getDocument()
        guard snapshot.exists else {
            throw UserProfileError.notFound
        }
        guard let data = snapshot.data() else {
            throw UserProfileError.malformed
        }
        
        let email = data["email"] as? String ?? ""
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        let firstName = data["firstName"] as? String
        let monthlyIncome = (data["monthlyIncome"] as? NSNumber)?.intValue ?? 0
        let monthlySavingsGoal = (data["monthlySavingsGoal"] as? NSNumber)?.intValue ?? 0
        let onboardingComplete = data["onboardingComplete"] as? Bool ?? false
        
        let isPremium = data["isPremium"] as? Bool ?? false
        let subscriptionPlan = SubscriptionPlan(rawValue: data["subscriptionPlan"] as? String ?? "")
        let subscriptionStatus = data["subscriptionStatus"] as? String
        let trialDays = (data["trialDays"] as? NSNumber)?.intValue
        let trialStartedAt = (data["trialStartedAt"] as? Timestamp)?.dateValue()
        
        let isFoundingMember = data["isFoundingMember"] as? Bool ?? false
        let foundingMemberNumber = (data["foundingMemberNumber"] as? NSNumber)?.intValue
        let lockedAnnualPriceCents = (data["lockedAnnualPriceCents"] as? NSNumber)?.intValue
        let lockedAnnualPriceCurrency = data["lockedAnnualPriceCurrency"] as? String
        let hasEarlySupporterBadge = data["hasEarlySupporterBadge"] as? Bool ?? false
        let futurePremiumFeaturesIncluded = data["futurePremiumFeaturesIncluded"] as? Bool ?? false
        
        return UserProfile(
            uid: uid,
            email: email,
            createdAt: createdAt,
            firstName: firstName,
            monthlyIncome: monthlyIncome,
            monthlySavingsGoal: monthlySavingsGoal,
            onboardingComplete: onboardingComplete,
            isPremium: isPremium,
            subscriptionPlan: subscriptionPlan,
            subscriptionStatus: subscriptionStatus,
            trialDays: trialDays,
            trialStartedAt: trialStartedAt,
            isFoundingMember: isFoundingMember,
            foundingMemberNumber: foundingMemberNumber,
            lockedAnnualPriceCents: lockedAnnualPriceCents,
            lockedAnnualPriceCurrency: lockedAnnualPriceCurrency,
            hasEarlySupporterBadge: hasEarlySupporterBadge,
            futurePremiumFeaturesIncluded: futurePremiumFeaturesIncluded
        )
    }
    
    func markOnboardingComplete(uid: String) async throws {
        try await db.collection("users").document(uid).updateData([
            "onboardingComplete": true
        ])
    }
    
    func updateOnboardingInputs(uid: String, firstName: String?, monthlyIncome: Int, monthlySavingsGoal: Int) async throws {
        var updates: [String: Any] = [
            "monthlyIncome": monthlyIncome,
            "monthlySavingsGoal": monthlySavingsGoal,
            "onboardingComplete": true
        ]
        
        if let firstName, !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            updates["firstName"] = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        try await db.collection("users").document(uid).updateData(updates)
    }
    
    func fetchFoundingAnnualOfferState() async throws -> FoundingAnnualOfferState {
        let offerRef = db.collection(foundingAnnualOfferRefPath.collection).document(foundingAnnualOfferRefPath.document)
        let snapshot = try await offerRef.getDocument()
        let data = snapshot.data() ?? [:]
        
        let limit = (data["limit"] as? NSNumber)?.intValue ?? defaultFoundingAnnualLimit
        let claimedCount = (data["claimedCount"] as? NSNumber)?.intValue ?? 0
        return FoundingAnnualOfferState(limit: limit, claimedCount: claimedCount)
    }
    
    func startPremiumTrial(uid: String, plan: SubscriptionPlan, trialDays: Int, annualPriceCents: Int, annualCurrency: String) async throws {
        let userRef = db.collection("users").document(uid)
        let offerRef = db.collection(foundingAnnualOfferRefPath.collection).document(foundingAnnualOfferRefPath.document)
        
        try await runTransaction { transaction in
            let userSnapshot = try transaction.getDocument(userRef)
            guard userSnapshot.exists else {
                throw SubscriptionError.missingUser
            }
            
            var userUpdates: [String: Any] = [
                "isPremium": true,
                "subscriptionPlan": plan.rawValue,
                "subscriptionStatus": "trial",
                "trialDays": trialDays,
                "trialStartedAt": FieldValue.serverTimestamp(),
                "subscriptionUpdatedAt": FieldValue.serverTimestamp()
            ]
            
            if plan == .annual {
                let userData = userSnapshot.data() ?? [:]
                let alreadyFounding = userData["isFoundingMember"] as? Bool ?? false
                
                if !alreadyFounding {
                    let offerSnapshot = try transaction.getDocument(offerRef)
                    let offerData = offerSnapshot.data() ?? [:]
                    
                    let limit = (offerData["limit"] as? NSNumber)?.intValue ?? self.defaultFoundingAnnualLimit
                    let claimedCount = (offerData["claimedCount"] as? NSNumber)?.intValue ?? 0
                    
                    if claimedCount < limit {
                        let memberNumber = claimedCount + 1
                        
                        userUpdates["isFoundingMember"] = true
                        userUpdates["foundingMemberNumber"] = memberNumber
                        userUpdates["foundingMemberSince"] = FieldValue.serverTimestamp()
                        userUpdates["lockedAnnualPriceCents"] = annualPriceCents
                        userUpdates["lockedAnnualPriceCurrency"] = annualCurrency
                        userUpdates["hasEarlySupporterBadge"] = true
                        userUpdates["futurePremiumFeaturesIncluded"] = true
                        
                        transaction.setData(
                            [
                                "limit": limit,
                                "claimedCount": memberNumber,
                                "updatedAt": FieldValue.serverTimestamp()
                            ],
                            forDocument: offerRef,
                            merge: true
                        )
                    } else {
                        transaction.setData(
                            [
                                "limit": limit,
                                "claimedCount": claimedCount,
                                "updatedAt": FieldValue.serverTimestamp()
                            ],
                            forDocument: offerRef,
                            merge: true
                        )
                    }
                }
            }
            
            transaction.setData(userUpdates, forDocument: userRef, merge: true)
            return
        }
    }
    
    private func runTransaction(_ body: @escaping (FirebaseFirestore.Transaction) throws -> Void) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            db.runTransaction({ transaction, errorPointer -> Any? in
                do {
                    try body(transaction)
                    return nil
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }, completion: { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: ())
            })
        }
    }
}

private enum UserProfileError: Error {
    case notFound
    case malformed
}

private enum SubscriptionError: Error {
    case missingUser
}
