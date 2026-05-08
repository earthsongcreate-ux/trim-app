import Foundation
import LocalAuthentication
import SwiftUI
import Combine

// MARK: - Biometric Type Detection

/// Represents the biometric capability available on the current device.
enum BiometricType: String {
    case faceID = "Face ID"
    case touchID = "Touch ID"
    case passcode = "Passcode"
    case none = "None"
    
    /// SF Symbol name appropriate for the biometric type.
    var systemImage: String {
        switch self {
        case .faceID:  return "faceid"
        case .touchID: return "touchid"
        case .passcode: return "lock.fill"
        case .none:    return "xmark.shield.fill"
        }
    }
}

// MARK: - Authentication Error

/// Structured authentication error with user-facing messages.
enum BiometricAuthError: LocalizedError, Equatable {
    case biometricsUnavailable
    case biometricsNotEnrolled
    case authenticationFailed
    case userCancelled
    case userFallback
    case systemCancel
    case passcodeNotSet
    case lockout
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .biometricsUnavailable:
            return "Biometric authentication is not available on this device."
        case .biometricsNotEnrolled:
            return "No biometric data is enrolled. Please set up Face ID or Touch ID in Settings."
        case .authenticationFailed:
            return "Authentication failed. Please try again."
        case .userCancelled:
            return "Authentication was cancelled."
        case .userFallback:
            return "Passcode authentication was requested."
        case .systemCancel:
            return "Authentication was interrupted by the system."
        case .passcodeNotSet:
            return "A device passcode is required. Please set one in Settings."
        case .lockout:
            return "Too many failed attempts. Use your device passcode to unlock."
        case .unknown(let message):
            return message
        }
    }
    
    /// Maps LAError codes to structured BiometricAuthError cases.
    static func from(_ error: Error) -> BiometricAuthError {
        guard let laError = error as? LAError else {
            return .unknown(error.localizedDescription)
        }
        
        switch laError.code {
        case .biometryNotAvailable:
            return .biometricsUnavailable
        case .biometryNotEnrolled:
            return .biometricsNotEnrolled
        case .authenticationFailed:
            return .authenticationFailed
        case .userCancel:
            return .userCancelled
        case .userFallback:
            return .userFallback
        case .systemCancel:
            return .systemCancel
        case .passcodeNotSet:
            return .passcodeNotSet
        case .biometryLockout:
            return .lockout
        default:
            return .unknown(laError.localizedDescription)
        }
    }
}

// MARK: - BiometricAuthManager

/// A clean, reusable service for managing biometric authentication state.
///
/// Inject as an `@StateObject` at the app root and pass via `.environmentObject()`.
/// Consumers observe `isAuthenticated` and `authError` reactively.
///
/// Usage:
/// ```swift
/// @StateObject private var biometricAuth = BiometricAuthManager()
///
/// // Trigger authentication
/// biometricAuth.authenticate()
///
/// // Check state
/// if biometricAuth.isAuthenticated { ... }
///
/// // Reset session
/// biometricAuth.logout()
/// ```
final class BiometricAuthManager: ObservableObject {
    
    // MARK: - Published State
    
    /// Whether the user has successfully authenticated in the current session.
    @Published private(set) var isAuthenticated: Bool = false
    
    /// Human-readable error message from the last failed authentication attempt.
    /// Empty string when no error is present.
    @Published private(set) var authError: String = ""
    
    /// The last structured error, if any. Useful for programmatic error handling.
    @Published private(set) var lastError: BiometricAuthError? = nil
    
    // MARK: - Computed Properties
    
    /// The biometric type available on the current device.
    var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Check if at least passcode is available
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                return .passcode
            }
            return .none
        }
        
        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .faceID // Treat Vision Pro optic ID as Face ID equivalent
        case .none:
            return .passcode
        @unknown default:
            return .passcode
        }
    }
    
    /// Whether any form of device authentication (biometric or passcode) is available.
    var isAuthenticationAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }
    
    /// Whether biometric-specific authentication (Face ID or Touch ID) is available.
    var isBiometricAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    // MARK: - Authentication
    
    /// Prompts the user for biometric authentication with passcode fallback.
    ///
    /// Uses `.deviceOwnerAuthentication` policy, which automatically falls back
    /// to the device passcode if biometrics fail or are unavailable.
    ///
    /// On success, sets `isAuthenticated = true` and clears any previous error.
    /// On failure, sets `isAuthenticated = false` and populates `authError`.
    func authenticate() {
        let context = LAContext()
        var policyError: NSError?
        
        // Clear previous error state before attempting
        clearError()
        
        // Verify device supports authentication
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &policyError) else {
            let error = BiometricAuthError.from(policyError ?? NSError(domain: LAErrorDomain, code: LAError.biometryNotAvailable.rawValue))
            handleFailure(error)
            return
        }
        
        let reason = "Access your financial data securely"
        
        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: reason
        ) { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if success {
                    self.handleSuccess()
                } else if let error = error {
                    self.handleFailure(BiometricAuthError.from(error))
                } else {
                    self.handleFailure(.authenticationFailed)
                }
            }
        }
    }
    
    /// Resets authentication state, effectively logging the user out.
    ///
    /// After calling this, `isAuthenticated` will be `false` and the UI
    /// should present the lock screen or authentication prompt.
    func logout() {
        isAuthenticated = false
        clearError()
    }
    
    // MARK: - Private Helpers
    
    private func handleSuccess() {
        isAuthenticated = true
        authError = ""
        lastError = nil
    }
    
    private func handleFailure(_ error: BiometricAuthError) {
        isAuthenticated = false
        authError = error.errorDescription ?? "An unknown error occurred."
        lastError = error
    }
    
    private func clearError() {
        authError = ""
        lastError = nil
    }
}
