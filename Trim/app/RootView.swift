import SwiftUI
import Combine

// MARK: - RootView

/// The app's top-level view that enforces authentication before granting access.
///
/// Owns `BiometricAuthManager` and `SessionManager` as the single source of truth.
/// All child views receive them via `.environmentObject()`.
///
/// Security layers:
/// 1. **Privacy shield** — opaque overlay during `.inactive`/`.background` to hide
///    financial data from the app switcher snapshot.
/// 2. **Session lock** — immediate lock on background; requires re-auth on return.
/// 3. **Inactivity timeout** — locks after 90s of no interaction while in foreground.
struct RootView: View {
    var body: some View {
        if FirebaseBootstrap.isConfigured {
            AuthenticatedRootView()
        } else {
            FirebaseSetupView()
        }
    }
}

struct AuthenticatedRootView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var authManager = BiometricAuthManager()
    @StateObject private var sessionManager = SessionManager()
    @Environment(\.scenePhase) private var scenePhase
    @State private var showPrivacyShield = false

    var body: some View {
        ZStack {
            if authViewModel.isCheckingSession {
                loadingView
            } else if authViewModel.isAuthenticated {
                if authViewModel.isLoadingProfile {
                    loadingView
                } else if authViewModel.profile == nil {
                    profileErrorView
                } else if authViewModel.profile?.onboardingComplete == false {
                    SecureView {
                        OnboardingView { firstName, monthlyIncome, monthlySavingsGoal in
                            Task {
                                await authViewModel.completeOnboarding(
                                    firstName: firstName,
                                    monthlyIncome: monthlyIncome,
                                    monthlySavingsGoal: monthlySavingsGoal
                                )
                            }
                        }
                    }
                    .transition(SecurityTransition.unlock)
                } else {
                    SecureView {
                        MainTabView()
                    }
                    .transition(SecurityTransition.unlock)
                }
            } else {
                AuthFlowView()
                    .transition(SecurityTransition.lock)
            }
            
            if showPrivacyShield {
                privacyOverlay
                    .zIndex(999)
                    .transition(SecurityTransition.shield)
            }
        }
        .animation(SecurityTransition.unlockAnimation, value: authViewModel.isAuthenticated)
        .animation(SecurityTransition.shieldAnimation, value: showPrivacyShield)
        .environmentObject(authViewModel)
        .environmentObject(authManager)
        .environmentObject(sessionManager)
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
        .onReceive(authManager.$isAuthenticated) { authenticated in
            if authenticated {
                sessionManager.startSession()
            }
        }
        .onReceive(sessionManager.$isLocked) { locked in
            if locked && authManager.isAuthenticated {
                authManager.logout()
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { _, isAuthed in
            if isAuthed {
                sessionManager.startSession()
            } else {
                authManager.logout()
                sessionManager.lock()
            }
        }
    }

    private var loadingView: some View {
        ZStack {
            TrimDesignSystem.Colors.background
                .ignoresSafeArea()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: TrimDesignSystem.Colors.accentPrimary))
                .scaleEffect(1.2)
        }
    }
    
    private var profileErrorView: some View {
        ZStack {
            TrimDesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: TrimDesignSystem.Spacing.l) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(TrimDesignSystem.Colors.error)
                
                Text(authViewModel.errorMessage ?? "We couldn’t load your account details. Please try again.")
                    .font(TrimDesignSystem.Typography.body)
                    .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, TrimDesignSystem.Spacing.xl)
                
                VStack(spacing: TrimDesignSystem.Spacing.m) {
                    Button {
                        Task { await authViewModel.retryProfileLoad() }
                    } label: {
                        Text("Try Again")
                            .font(TrimDesignSystem.Typography.subheader)
                            .foregroundColor(TrimDesignSystem.Colors.background)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(TrimDesignSystem.Colors.accentPrimary)
                            .cornerRadius(TrimDesignSystem.Radius.medium)
                    }
                    .trimPressAnimation()
                    
                    Button {
                        authViewModel.signOut()
                    } label: {
                        Text("Sign Out")
                            .font(TrimDesignSystem.Typography.body)
                            .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                    }
                    .trimPressAnimation()
                }
                .padding(.horizontal, TrimDesignSystem.Spacing.xl)
            }
        }
    }
    
    // MARK: - Privacy Overlay
    
    /// Opaque shield that covers all content to prevent data exposure
    /// in the app switcher and during system transitions.
    private var privacyOverlay: some View {
        ZStack {
            TrimDesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: TrimDesignSystem.Spacing.m) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
                
                Text("Trim")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(TrimDesignSystem.Colors.textPrimary)
            }
        }
    }
    
    // MARK: - Lifecycle Handling
    
    /// Centralized handler for all scene phase transitions.
    ///
    /// Phase flow:
    /// - `.active` → `.inactive` → `.background` (leaving)
    /// - `.background` → `.inactive` → `.active` (returning)
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            showPrivacyShield = false
        case .inactive:
            showPrivacyShield = true
        case .background:
            showPrivacyShield = true
            sessionManager.handleDidEnterBackground()
        @unknown default:
            break
        }
    }
}

struct FirebaseSetupView: View {
    var body: some View {
        ZStack {
            TrimDesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: TrimDesignSystem.Spacing.l) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(TrimDesignSystem.Colors.error)
                
                Text("Firebase isn’t configured")
                    .font(TrimDesignSystem.Typography.header)
                    .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                
                Text("To run Trim in the Simulator, add your GoogleService-Info.plist file to the app target.")
                    .font(TrimDesignSystem.Typography.body)
                    .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, TrimDesignSystem.Spacing.xl)
                
                Link("Firebase iOS Setup Guide", destination: URL(string: "https://firebase.google.com/docs/ios/setup")!)
                    .font(TrimDesignSystem.Typography.subheader)
                    .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
            }
        }
    }
}
