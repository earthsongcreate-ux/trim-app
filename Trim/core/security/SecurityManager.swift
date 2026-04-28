import Foundation
import LocalAuthentication
import Combine
import SwiftUI

class SecurityManager: ObservableObject {
    static let shared = SecurityManager()
    
    @Published var isUnlocked: Bool = false
    @Published var isBiometricsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isBiometricsEnabled, forKey: "isBiometricsEnabled")
            if isBiometricsEnabled && !isUnlocked {
                authenticate()
            }
        }
    }
    
    // Privacy protection when backgrounded
    @Published var isPrivacyMaskEnabled: Bool = false
    
    private var lastActiveTime: Date = Date()
    private let sessionTimeout: TimeInterval = 60 // 60 seconds of inactivity triggers a lock
    
    init() {
        self.isBiometricsEnabled = UserDefaults.standard.bool(forKey: "isBiometricsEnabled")
        // If biometrics are not enabled, the app is implicitly "unlocked" from the manager's perspective
        self.isUnlocked = !self.isBiometricsEnabled 
    }
    
    func authenticate() {
        guard isBiometricsEnabled else {
            isUnlocked = true
            return
        }
        
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Unlock Trim to access your secure financial data."
            
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isUnlocked = true
                        self.lastActiveTime = Date()
                    } else {
                        self.isUnlocked = false
                        // Error handling could be added here
                    }
                }
            }
        } else {
            // No biometrics or passcode available
            DispatchQueue.main.async {
                self.isUnlocked = true 
            }
        }
    }
    
    // MARK: - App Lifecycle Handlers
    
    func handleAppBackgrounding() {
        // Immediately mask UI to protect snapshot in App Switcher
        isPrivacyMaskEnabled = true
        lastActiveTime = Date()
    }
    
    func handleAppForegrounding() {
        isPrivacyMaskEnabled = false
        
        guard isBiometricsEnabled else { return }
        
        let inactiveDuration = Date().timeIntervalSince(lastActiveTime)
        if inactiveDuration > sessionTimeout {
            isUnlocked = false
            authenticate()
        }
    }
    
    func requireAuthForSensitiveAction(completion: @escaping (Bool) -> Void) {
        guard isBiometricsEnabled else {
            completion(true)
            return
        }
        
        // If they recently authenticated, allow it. Otherwise prompt again.
        let inactiveDuration = Date().timeIntervalSince(lastActiveTime)
        if inactiveDuration < 300 && isUnlocked { // 5 min grace period for sensitive in-app actions
            completion(true)
            return
        }
        
        let context = LAContext()
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Verify identity to proceed.") { success, _ in
            DispatchQueue.main.async {
                if success {
                    self.lastActiveTime = Date()
                }
                completion(success)
            }
        }
    }
}
