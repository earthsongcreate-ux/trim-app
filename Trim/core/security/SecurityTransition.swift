import SwiftUI

// MARK: - Security Transitions

/// Defines the app's security transition constants and prebuilt transitions.
///
/// All security-related view changes (lock, unlock, privacy shield) use these
/// shared definitions to maintain consistent, premium-feeling motion across
/// the entire app.
///
/// Design principles:
/// - **Locking** is fast and decisive — the user should feel immediate protection
/// - **Unlocking** is slightly slower with scale — gives a sense of "opening up"
/// - **Privacy shield** is near-instant — must beat the system snapshot timing
enum SecurityTransition {
    
    // MARK: - Durations
    
    /// Duration for locking transitions (lock screen appearing).
    /// Fast and decisive — security feels immediate.
    static let lockDuration: Double = 0.2
    
    /// Duration for unlocking transitions (content appearing).
    /// Slightly slower — gives a sense of the app "opening up".
    static let unlockDuration: Double = 0.3
    
    /// Duration for the privacy shield overlay.
    /// Near-instant — must beat the iOS app switcher snapshot.
    static let shieldDuration: Double = 0.12
    
    // MARK: - Animations
    
    /// Animation curve for locking — quick ease-out for immediacy.
    static let lockAnimation: Animation = .easeOut(duration: lockDuration)
    
    /// Animation curve for unlocking — smooth ease-in-out for polish.
    static let unlockAnimation: Animation = .easeInOut(duration: unlockDuration)
    
    /// Animation curve for the privacy shield — near-instant linear.
    static let shieldAnimation: Animation = .easeOut(duration: shieldDuration)
    
    // MARK: - Transitions
    
    /// Transition when the lock screen appears.
    /// Pure opacity — no movement, immediate visual protection.
    static let lock: AnyTransition = .opacity
    
    /// Transition when authenticated content appears.
    /// Opacity + subtle scale-up from 97% — content "breathes in".
    static let unlock: AnyTransition = .opacity
        .combined(with: .scale(scale: 0.97, anchor: .center))
    
    /// Transition for the privacy shield overlay.
    /// Pure opacity — fastest possible coverage.
    static let shield: AnyTransition = .opacity
}
