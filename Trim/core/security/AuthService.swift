import Foundation
import Combine
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

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
#if canImport(FirebaseAuth)
        if Auth.auth().currentUser != nil {
            // User is signed in with Firebase. Refresh the token.
            Auth.auth().currentUser?.getIDTokenForcingRefresh(true) { token, error in
                if let token = token {
                    self.saveTokens(AuthTokens(accessToken: token, refreshToken: ""))
                    DispatchQueue.main.async {
                        self.isAuthenticated = true
                    }
                } else {
                    self.signOut()
                }
            }
        } else {
            self.isAuthenticated = false
        }
#else
        self.isAuthenticated = false
#endif
    }
    
    // MARK: - Authentication Methods
    
    func signInWithApple(identityToken: String, authCode: String) {
        startAuth()
        // Here you would create an OAuth credential for Firebase and sign in
        // Example: let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: identityToken, rawNonce: "")
        // For now, mock completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.completeAuth(success: true, tokens: self.mockTokens())
        }
    }
    
    func signInWithGoogle(idToken: String) {
        startAuth()
        // Google credential sign in
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.completeAuth(success: true, tokens: self.mockTokens())
        }
    }
    
    func signInWithEmail(email: String, password: String) {
        startAuth()
#if canImport(FirebaseAuth)
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            if let error = error {
                self.completeAuth(success: false, error: error.localizedDescription)
                return
            }
            
            authResult?.user.getIDTokenForcingRefresh(true) { idToken, error in
                if let error = error {
                    self.completeAuth(success: false, error: error.localizedDescription)
                    return
                }
                
                if let idToken = idToken {
                    self.completeAuth(success: true, tokens: AuthTokens(accessToken: idToken, refreshToken: ""))
                } else {
                    self.completeAuth(success: false, error: "Failed to retrieve ID token")
                }
            }
        }
#else
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.completeAuth(success: true, tokens: self.mockTokens())
        }
#endif
    }

    func signUpWithEmail(email: String, password: String) {
        startAuth()
#if canImport(FirebaseAuth)
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            if let error = error {
                self.completeAuth(success: false, error: error.localizedDescription)
                return
            }
            
            authResult?.user.getIDTokenForcingRefresh(true) { idToken, error in
                if let error = error {
                    self.completeAuth(success: false, error: error.localizedDescription)
                    return
                }
                
                if let idToken = idToken {
                    self.completeAuth(success: true, tokens: AuthTokens(accessToken: idToken, refreshToken: ""))
                } else {
                    self.completeAuth(success: false, error: "Failed to retrieve ID token")
                }
            }
        }
#else
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.completeAuth(success: true, tokens: self.mockTokens())
        }
#endif
    }
    
    func signOut() {
        do {
#if canImport(FirebaseAuth)
            try Auth.auth().signOut()
#endif
            try KeychainManager.shared.delete(key: accessTokenKey)
            try KeychainManager.shared.delete(key: refreshTokenKey)
            DispatchQueue.main.async {
                self.isAuthenticated = false
            }
        } catch {
            print("Failed to clear keychain on sign out: \(error)")
        }
    }
    
    // MARK: - Token Management
    
    func refreshSession() {
        checkExistingSession()
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
        DispatchQueue.main.async {
            self.isLoading = true
            self.authError = nil
        }
    }
    
    private func completeAuth(success: Bool, tokens: AuthTokens? = nil, error: String? = nil) {
        DispatchQueue.main.async {
            self.isLoading = false
            if success, let tokens = tokens {
                self.saveTokens(tokens)
                
                // Call backend verify endpoint to sync user
                self.syncWithBackend(token: tokens.accessToken)
                
                self.isAuthenticated = true
            } else {
                self.authError = error ?? "Authentication failed. Please try again."
                self.isAuthenticated = false
            }
        }
    }
    
    private func syncWithBackend(token: String) {
        let backendUrl = ProcessInfo.processInfo.environment["TRIM_API_URL"] ?? "http://localhost:3001"
        guard let url = URL(string: "\(backendUrl)/api/v1/auth/verify") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Backend sync failed: \(error.localizedDescription)")
            } else if let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 {
                print("Backend synced successfully")
            }
        }.resume()
    }
    
    private func mockTokens() -> AuthTokens {
        return AuthTokens(
            accessToken: "mock_jwt_access_token_\(UUID().uuidString)",
            refreshToken: "mock_jwt_refresh_token_\(UUID().uuidString)"
        )
    }
}
