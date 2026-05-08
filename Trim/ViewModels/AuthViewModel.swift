import Foundation
import Combine
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {
    @Published private(set) var user: User?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isCheckingSession: Bool = true
    @Published var errorMessage: String?
    
    private let authService: AuthService
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    init(authService: AuthService = .shared) {
        self.authService = authService
        start()
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    var isAuthenticated: Bool {
        user != nil
    }
    
    var userEmail: String? {
        user?.email
    }
    
    func start() {
        if authStateHandle == nil {
            authStateHandle = authService.addAuthStateDidChangeListener { [weak self] user in
                Task { @MainActor in
                    self?.user = user
                    self?.isCheckingSession = false
                }
            }
        }
        
        user = authService.currentUser
        isCheckingSession = false
    }
    
    func signIn(email: String, password: String) async {
        await runAuthTask { [self] in
            _ = try await self.authService.signIn(email: email, password: password)
        }
    }
    
    func signUp(email: String, password: String) async {
        await runAuthTask { [self] in
            _ = try await self.authService.createUser(email: email, password: password)
        }
    }
    
    func sendPasswordReset(email: String) async {
        await runAuthTask { [self] in
            try await self.authService.sendPasswordReset(email: email)
        }
    }
    
    func signOut() {
        errorMessage = nil
        do {
            try authService.signOut()
        } catch {
            errorMessage = "Couldn’t sign out. Please try again."
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return trimmed.contains("@") && trimmed.contains(".")
    }
    
    private func runAuthTask(_ work: @escaping () async throws -> Void) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await work()
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
    }
    
    private func friendlyMessage(for error: Error) -> String {
        let nsError = error as NSError
        if let code = AuthErrorCode(rawValue: nsError.code) {
            switch code {
            case .invalidEmail:
                return "That email address doesn’t look right."
            case .wrongPassword, .invalidCredential:
                return "Incorrect email or password."
            case .userNotFound:
                return "No account found for that email."
            case .emailAlreadyInUse:
                return "That email is already in use. Try signing in instead."
            case .weakPassword:
                return "Your password is too weak. Use at least 6 characters."
            case .networkError:
                return "Network error. Check your connection and try again."
            case .tooManyRequests:
                return "Too many attempts. Please try again later."
            default:
                return "Something went wrong. Please try again."
            }
        }
        
        return "Something went wrong. Please try again."
    }
}
