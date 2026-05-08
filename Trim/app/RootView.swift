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
    
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var authManager = BiometricAuthManager()
    @StateObject private var sessionManager = SessionManager()
    @Environment(\.scenePhase) private var scenePhase
    
    /// Controls the privacy overlay that hides content in the app switcher.
    @State private var showPrivacyShield = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            if authViewModel.isCheckingSession {
                loadingView
            } else if authViewModel.isAuthenticated {
                SecureView {
                    MainTabView()
                }
                .transition(SecurityTransition.unlock)
            } else {
                AuthFlowView()
                    .transition(SecurityTransition.lock)
            }
            
            // Privacy shield — covers ALL content during inactive/background.
            // Prevents financial data from appearing in the app switcher.
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
        
        // MARK: — Lifecycle: Scene Phase
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
        
        // MARK: — Reactive: Auth Success → Start Session
        .onReceive(authManager.$isAuthenticated) { authenticated in
            if authenticated {
                sessionManager.startSession()
            }
        }
        
        // MARK: — Reactive: Session Expired → Require Re-auth
        .onReceive(sessionManager.$isLocked) { locked in
            if locked && authManager.isAuthenticated {
                authManager.logout()
            }
        }
        
        // MARK: — Reactive: Firebase Auth → Session Gate
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
            // App is fully visible — remove privacy shield.
            showPrivacyShield = false
            
            // Session was locked on background entry.
            // The reactive .onReceive binding already triggered logout,
            // and LockView will auto-trigger re-authentication on appear.
            
        case .inactive:
            // App is transitioning (app switcher, notification shade, etc.).
            // Show privacy shield immediately to hide financial data from
            // the system snapshot used in the app switcher.
            showPrivacyShield = true
            
        case .background:
            // App is fully backgrounded — lock the session immediately.
            showPrivacyShield = true
            sessionManager.handleDidEnterBackground()
            
        @unknown default:
            break
        }
    }
}
