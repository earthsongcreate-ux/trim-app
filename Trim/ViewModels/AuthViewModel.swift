import Foundation
import Combine
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {
    @Published private(set) var user: User?
    @Published private(set) var profile: UserProfile?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isCheckingSession: Bool = true
    @Published private(set) var isLoadingProfile: Bool = false
    @Published var errorMessage: String?
    
    private let authService: AuthService
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    init(authService: AuthService? = nil) {
        self.authService = authService ?? .shared
        start()
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    var isAuthenticated: Bool {
        user != nil
    }
    
    var userEmail: String? {
        user?.email
    }
    
    func start() {
        if authStateHandle == nil {
            authStateHandle = authService.addAuthStateDidChangeListener { [weak self] user in
                Task { @MainActor in
                    self?.handleAuthStateChange(user)
                }
            }
        }
        
        user = authService.currentUser
        
        if let user {
            Task { @MainActor in
                await loadUserProfile(for: user, isInitial: true)
            }
        } else {
            isCheckingSession = false
        }
    }
    
    func signIn(email: String, password: String) async {
        await runAuthTask { [self] in
            _ = try await self.authService.signIn(email: email, password: password)
        }
    }
    
    func signUp(email: String, password: String) async {
        await runAuthTask { [self] in
            let user = try await self.authService.createUser(email: email, password: password)
            do {
                try await UserProfileService.shared.createUserProfileIfNeeded(user: user)
                self.profile = try await UserProfileService.shared.fetchUserProfile(uid: user.uid)
            } catch {
                try? self.authService.signOut()
                throw AuthFlowError.profileSetupFailed
            }
        }
    }
    
    func sendPasswordReset(email: String) async {
        await runAuthTask { [self] in
            try await self.authService.sendPasswordReset(email: email)
        }
    }
    
    func signOut() {
        errorMessage = nil
        do {
            try authService.signOut()
            try? KeychainManager.shared.delete(key: "trim_access_token")
            profile = nil
        } catch {
            errorMessage = "Couldn’t sign out. Please try again."
        }
    }
    
    func completeOnboarding(firstName: String?, monthlyIncome: Int, monthlySavingsGoal: Int) async {
        guard let user else { return }
        guard !isLoadingProfile else { return }
        
        isLoadingProfile = true
        defer { isLoadingProfile = false }
        
        do {
            try await UserProfileService.shared.updateOnboardingInputs(
                uid: user.uid,
                firstName: firstName,
                monthlyIncome: monthlyIncome,
                monthlySavingsGoal: monthlySavingsGoal
            )
            if let current = profile {
                profile = UserProfile(
                    uid: current.uid,
                    email: current.email,
                    createdAt: current.createdAt,
                    firstName: firstName ?? current.firstName,
                    monthlyIncome: monthlyIncome,
                    monthlySavingsGoal: monthlySavingsGoal,
                    onboardingComplete: true,
                    isPremium: current.isPremium,
                    subscriptionPlan: current.subscriptionPlan,
                    subscriptionStatus: current.subscriptionStatus,
                    trialDays: current.trialDays,
                    trialStartedAt: current.trialStartedAt,
                    isFoundingMember: current.isFoundingMember,
                    foundingMemberNumber: current.foundingMemberNumber,
                    lockedAnnualPriceCents: current.lockedAnnualPriceCents,
                    lockedAnnualPriceCurrency: current.lockedAnnualPriceCurrency,
                    hasEarlySupporterBadge: current.hasEarlySupporterBadge,
                    futurePremiumFeaturesIncluded: current.futurePremiumFeaturesIncluded
                )
            } else {
                profile = try await UserProfileService.shared.fetchUserProfile(uid: user.uid)
            }
        } catch {
            errorMessage = "We couldn’t finish onboarding. Please try again."
        }
    }

    func startPremiumTrial(plan: SubscriptionPlan) async -> Bool {
        guard let user else { return false }
        guard !isLoadingProfile else { return false }
        
        isLoadingProfile = true
        defer { isLoadingProfile = false }
        
        do {
            try await UserProfileService.shared.startPremiumTrial(
                uid: user.uid,
                plan: plan,
                trialDays: 7,
                annualPriceCents: 9900,
                annualCurrency: "USD"
            )
            profile = try await UserProfileService.shared.fetchUserProfile(uid: user.uid)
            return true
        } catch {
            errorMessage = "We couldn’t start your trial. Please try again."
            return false
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return trimmed.contains("@") && trimmed.contains(".")
    }
    
    private func runAuthTask(_ work: @escaping () async throws -> Void) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await work()
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
    }
    
    private func friendlyMessage(for error: Error) -> String {
        if let error = error as? AuthFlowError, let message = error.errorDescription {
            return message
        }
        
        let nsError = error as NSError
        if let code = AuthErrorCode(rawValue: nsError.code) {
            switch code {
            case .invalidEmail:
                return "That email address doesn’t look right."
            case .wrongPassword, .invalidCredential:
                return "Incorrect email or password."
            case .userNotFound:
                return "No account found for that email."
            case .emailAlreadyInUse:
                return "That email is already in use. Try signing in instead."
            case .weakPassword:
                return "Your password is too weak. Use at least 6 characters."
            case .networkError:
                return "Network error. Check your connection and try again."
            case .tooManyRequests:
                return "Too many attempts. Please try again later."
            default:
                return "Something went wrong. Please try again."
            }
        }
        
        return "Something went wrong. Please try again."
    }
    
    private func handleAuthStateChange(_ user: User?) {
        self.user = user
        if user == nil {
            profile = nil
            try? KeychainManager.shared.delete(key: "trim_access_token")
            isCheckingSession = false
            isLoadingProfile = false
            return
        }
        
        Task { @MainActor in
            await refreshBackendToken(for: user!)
            await loadUserProfile(for: user!, isInitial: false)
        }
    }
    
    private func loadUserProfile(for user: User, isInitial: Bool) async {
        if isInitial {
            isCheckingSession = true
        }
        
        isLoadingProfile = true
        defer {
            isLoadingProfile = false
            if isInitial {
                isCheckingSession = false
            }
        }
        
        do {
            await refreshBackendToken(for: user)
            try await UserProfileService.shared.createUserProfileIfNeeded(user: user)
            profile = try await UserProfileService.shared.fetchUserProfile(uid: user.uid)
        } catch {
            profile = nil
            errorMessage = "We couldn’t load your account details. Please try again."
        }
    }

    private func refreshBackendToken(for user: User) async {
        do {
            let token = try await fetchFirebaseIdToken(for: user)
            try KeychainManager.shared.save(key: "trim_access_token", value: token)
        } catch {
            try? KeychainManager.shared.delete(key: "trim_access_token")
        }
    }
    
    private func fetchFirebaseIdToken(for user: User) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            user.getIDTokenForcingRefresh(true) { token, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let token, !token.isEmpty else {
                    continuation.resume(throwing: AuthFlowError.profileSetupFailed)
                    return
                }
                continuation.resume(returning: token)
            }
        }
    }
}

private enum AuthFlowError: LocalizedError {
    case profileSetupFailed
    
    var errorDescription: String? {
        switch self {
        case .profileSetupFailed:
            return "We couldn’t finish setting up your account. Please try again."
        }
    }
}
