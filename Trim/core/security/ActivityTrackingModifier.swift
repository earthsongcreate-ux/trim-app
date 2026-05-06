import SwiftUI

// MARK: - Activity Tracking Modifier

/// A `ViewModifier` that detects user interactions (taps, drags, scrolls)
/// and resets the `SessionManager` inactivity timer.
///
/// Apply this modifier to any view that should contribute to keeping
/// the session alive. It uses a `simultaneousGesture` to avoid
/// interfering with existing gesture handlers in child views.
///
/// Preferred usage is via the `.trackSessionActivity()` extension:
/// ```swift
/// MyView()
///     .trackSessionActivity()
/// ```
///
/// **Note:** `SessionManager` must be available in the environment
/// (injected by `RootView`).
struct ActivityTrackingModifier: ViewModifier {
    
    @EnvironmentObject private var sessionManager: SessionManager
    
    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        sessionManager.resetTimer()
                    }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { _ in
                        sessionManager.resetTimer()
                    }
            )
    }
}

// MARK: - View Extension

extension View {
    
    /// Tracks user interactions and resets the session inactivity timer.
    ///
    /// Attach this to any view hierarchy that should keep the session alive
    /// while the user is actively engaging with it. Safe to nest — multiple
    /// tracking layers don't conflict because `resetTimer()` is idempotent.
    ///
    /// ```swift
    /// DashboardView()
    ///     .trackSessionActivity()
    /// ```
    func trackSessionActivity() -> some View {
        modifier(ActivityTrackingModifier())
    }
}
