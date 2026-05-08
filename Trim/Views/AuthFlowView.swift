import SwiftUI

enum AuthRoute: Hashable {
    case register
    case forgotPassword
}

struct AuthFlowView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var path: [AuthRoute] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            LoginView(
                onCreateAccount: { path.append(.register) },
                onForgotPassword: { path.append(.forgotPassword) }
            )
            .navigationDestination(for: AuthRoute.self) { route in
                switch route {
                case .register:
                    RegisterView(
                        onBackToLogin: {
                            if !path.isEmpty { path.removeLast() }
                        }
                    )
                case .forgotPassword:
                    ForgotPasswordView(
                        onBackToLogin: {
                            if !path.isEmpty { path.removeLast() }
                        }
                    )
                }
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { _, isAuthed in
            if isAuthed {
                path.removeAll()
            }
        }
    }
}
