import Foundation
import Combine

/// Auth tokens payload
struct AuthTokens {
    let accessToken: String
    let refreshToken: String
}

/// Service responsible for handling authentication logic, token persistence, and session state.
final class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var authError: String? = nil
    
    private let accessTokenKey = "trim_access_token"
    private let refreshTokenKey = "trim_refresh_token"
    
    private init() {
        checkExistingSession()
    }
    
    /// Verifies if tokens exist in the keychain and attempts to validate/refresh them.
    func checkExistingSession() {
        do {
            let accessToken = try KeychainManager.shared.retrieve(key: accessTokenKey)
            // In a real app, verify the JWT expiry here.
            // If expired, use refreshToken to get a new one.
            if !accessToken.isEmpty {
                self.isAuthenticated = true
            }
        } catch {
            self.isAuthenticated = false
        }
    }
    
    // MARK: - Authentication Methods
    
    func signInWithApple(identityToken: String, authCode: String) {
        startAuth()
        
        // Simulate network request to backend
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.completeAuth(success: true, tokens: self.mockTokens())
        }
    }
    
    func signInWithGoogle(idToken: String) {
        startAuth()
        
        // Simulate network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.completeAuth(success: true, tokens: self.mockTokens())
        }
    }
    
    func signInWithEmail(email: String, password: String) {
        startAuth()
        
        // Simulate network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if email.isEmpty || password.isEmpty {
                self.completeAuth(success: false, error: "Invalid email or password.")
            } else {
                self.completeAuth(success: true, tokens: self.mockTokens())
            }
        }
    }
    
    func signOut() {
        do {
            try KeychainManager.shared.delete(key: accessTokenKey)
            try KeychainManager.shared.delete(key: refreshTokenKey)
            self.isAuthenticated = false
        } catch {
            print("Failed to clear keychain on sign out: \(error)")
        }
    }
    
    // MARK: - Token Management
    
    /// Uses the refresh token to get a new access token
    func refreshSession() {
        do {
            let _ = try KeychainManager.shared.retrieve(key: refreshTokenKey)
            // Call backend /auth/refresh with refresh token
            // On success, store new tokens
        } catch {
            self.signOut()
        }
    }
    
    private func saveTokens(_ tokens: AuthTokens) {
        do {
            try KeychainManager.shared.save(key: accessTokenKey, value: tokens.accessToken)
            try KeychainManager.shared.save(key: refreshTokenKey, value: tokens.refreshToken)
        } catch {
            print("Failed to save tokens: \(error)")
        }
    }
    
    // MARK: - Helpers
    
    private func startAuth() {
        isLoading = true
        authError = nil
    }
    
    private func completeAuth(success: Bool, tokens: AuthTokens? = nil, error: String? = nil) {
        isLoading = false
        if success, let tokens = tokens {
            saveTokens(tokens)
            isAuthenticated = true
        } else {
            authError = error ?? "Authentication failed. Please try again."
            isAuthenticated = false
        }
    }
    
    private func mockTokens() -> AuthTokens {
        return AuthTokens(
            accessToken: "mock_jwt_access_token_\(UUID().uuidString)",
            refreshToken: "mock_jwt_refresh_token_\(UUID().uuidString)"
        )
    }
}
