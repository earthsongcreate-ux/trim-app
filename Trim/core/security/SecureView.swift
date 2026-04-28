import SwiftUI

// MARK: - SecureView

/// A generic wrapper that gates content behind the active session lock
/// and automatically tracks user interactions to keep the session alive.
///
/// Reads `SessionManager` from the environment. When the session is locked,
/// renders `LockView` (which handles authentication internally). When unlocked,
/// renders the protected content with built-in activity tracking.
///
/// Usage:
/// ```swift
/// SecureView {
///     DashboardView()
/// }
///
/// SecureView {
///     TransactionDetailView(transaction: tx)
/// }
/// ```
///
/// **Important:** Both `BiometricAuthManager` and `SessionManager` must be
/// injected as environment objects by an ancestor view (handled by `RootView`).
struct SecureView<Content: View>: View {
    
    @EnvironmentObject private var sessionManager: SessionManager
    
    private let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            if sessionManager.isLocked {
                LockView()
                    .transition(SecurityTransition.lock)
            } else {
                content
                    .trackSessionActivity()
                    .sessionLockIndicator()
                    .transition(SecurityTransition.unlock)
            }
        }
        .animation(
            sessionManager.isLocked
                ? SecurityTransition.lockAnimation
                : SecurityTransition.unlockAnimation,
            value: sessionManager.isLocked
        )
    }
}
