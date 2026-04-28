import SwiftUI

// MARK: - SessionLockIndicator

/// A subtle, non-interactive indicator that visually confirms the session
/// is secured. Displays a small lock icon with "Secure session active" text.
///
/// Design:
/// - SF Symbol `lock.fill` at 10pt + microcopy at 12pt
/// - Secondary text color (#94A3B8) — blends into headers without competing
/// - Positioned top-trailing via the `.sessionLockIndicator()` modifier
///
/// This component is purely decorative — it carries no tap target and
/// does not affect layout of surrounding content.
struct SessionLockIndicator: View {
    
    var body: some View {
        HStack(spacing: TrimDesignSystem.Spacing.xs) {
            Image(systemName: "lock.fill")
                .font(.system(size: 10, weight: .medium))
            Text("Secure session active")
                .font(.system(size: 12))
        }
        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
        .allowsHitTesting(false)
        .accessibilityLabel("Secure session active")
        .accessibilityHidden(true)
    }
}

// MARK: - View Modifier

/// Overlays the lock indicator in the top-trailing corner of the view.
///
/// Applied automatically by `SecureView` — no manual integration needed.
struct SessionLockIndicatorModifier: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                SessionLockIndicator()
                    .padding(.top, TrimDesignSystem.Spacing.m)
                    .padding(.trailing, TrimDesignSystem.Spacing.m)
            }
    }
}

// MARK: - View Extension

extension View {
    
    /// Adds a subtle lock indicator to the top-right corner of the view.
    ///
    /// ```swift
    /// DashboardView()
    ///     .sessionLockIndicator()
    /// ```
    func sessionLockIndicator() -> some View {
        modifier(SessionLockIndicatorModifier())
    }
}
