import Foundation
import Combine
import SwiftUI

// MARK: - Session State

/// Represents the current state of the user session.
enum SessionState: Equatable {
    case active
    case locked
    case expired
    
    /// Whether the session currently allows access to protected content.
    var isAccessible: Bool {
        self == .active
    }
}

// MARK: - SessionManager

/// Manages automatic session locking based on user inactivity.
///
/// Tracks the last interaction timestamp and locks the session when
/// the configured timeout elapses without activity. Designed to work
/// alongside `BiometricAuthManager` — this manager owns the *when* to
/// lock; the auth manager owns the *how* to unlock.
///
/// Usage:
/// ```swift
/// @StateObject private var session = SessionManager()
///
/// // Start tracking after successful authentication
/// session.startSession()
///
/// // Reset on any user interaction
/// session.resetTimer()
///
/// // Manual lock (e.g., from settings)
/// session.lock()
///
/// // Lifecycle integration
/// session.handleDidEnterBackground()
/// session.handleWillEnterForeground()
/// ```
final class SessionManager: ObservableObject {
    
    // MARK: - Configuration
    
    /// Default inactivity timeout in seconds.
    static let defaultTimeout: TimeInterval = 90
    
    /// The configured inactivity timeout. Changing this resets the active timer.
    var timeout: TimeInterval {
        didSet {
            guard timeout > 0 else {
                timeout = Self.defaultTimeout
                return
            }
            if sessionState == .active {
                scheduleTimer()
            }
        }
    }
    
    // MARK: - Published State
    
    /// Whether the session is currently locked due to inactivity or manual lock.
    @Published private(set) var isLocked: Bool = true
    
    /// The current session state for consumers that need richer state handling.
    @Published private(set) var sessionState: SessionState = .locked
    
    /// Time remaining before the session locks, in seconds.
    /// Returns 0 when the session is already locked.
    @Published private(set) var timeRemaining: TimeInterval = 0
    
    // MARK: - Private State
    
    private var inactivityTimer: Timer?
    private var countdownTimer: Timer?
    private var lastActivityTimestamp: Date = Date()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(timeout: TimeInterval = SessionManager.defaultTimeout) {
        self.timeout = timeout > 0 ? timeout : Self.defaultTimeout
    }
    
    deinit {
        invalidateTimers()
    }
    
    // MARK: - Session Lifecycle
    
    /// Starts or resumes a session, marking it as active and beginning
    /// the inactivity countdown.
    ///
    /// Call this after a successful biometric authentication.
    func startSession() {
        isLocked = false
        sessionState = .active
        lastActivityTimestamp = Date()
        scheduleTimer()
    }
    
    /// Resets the inactivity timer, extending the session.
    ///
    /// Call this on any meaningful user interaction (tap, scroll, navigation).
    /// Safe to call frequently — the timer is rescheduled, not stacked.
    func resetTimer() {
        guard sessionState == .active else { return }
        lastActivityTimestamp = Date()
        scheduleTimer()
    }
    
    /// Manually locks the session immediately.
    ///
    /// Use for explicit lock actions (e.g., lock button in settings).
    func lock() {
        invalidateTimers()
        isLocked = true
        sessionState = .locked
        timeRemaining = 0
    }
    
    // MARK: - App Lifecycle Integration
    
    /// Call when the app enters the background or becomes inactive.
    ///
    /// Immediately locks the session to protect sensitive financial data.
    /// The user must re-authenticate when the app returns to the foreground.
    func handleDidEnterBackground() {
        lock()
    }
    
    /// Call when the app returns to the foreground.
    ///
    /// The session remains locked after backgrounding — the caller
    /// is responsible for triggering re-authentication to unlock.
    func handleWillEnterForeground() {
        // Session is already locked from handleDidEnterBackground().
        // No action needed — RootView coordinates re-auth via its
        // reactive .onReceive bindings.
    }
    
    // MARK: - Private Implementation
    
    /// Schedules (or reschedules) the inactivity timer.
    ///
    /// - Parameter remainingTime: Optional override for the countdown duration.
    ///   Defaults to the full timeout when `nil`.
    private func scheduleTimer(remainingTime: TimeInterval? = nil) {
        invalidateTimers()
        
        let duration = remainingTime ?? timeout
        timeRemaining = duration
        
        // Primary lock timer — fires once when timeout elapses
        inactivityTimer = Timer.scheduledTimer(
            withTimeInterval: duration,
            repeats: false
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.lock()
            }
        }
        
        // Countdown timer — updates `timeRemaining` every second for UI consumers
        countdownTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0,
            repeats: true
        ) { [weak self] _ in
            guard let self = self else { return }
            let elapsed = Date().timeIntervalSince(self.lastActivityTimestamp)
            let remaining = max(0, self.timeout - elapsed)
            
            DispatchQueue.main.async {
                self.timeRemaining = remaining
            }
        }
    }
    
    /// Invalidates and releases all active timers.
    private func invalidateTimers() {
        inactivityTimer?.invalidate()
        inactivityTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
}
