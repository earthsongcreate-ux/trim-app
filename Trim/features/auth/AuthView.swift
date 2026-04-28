import SwiftUI

struct AuthView: View {
    @StateObject private var authService = AuthService.shared
    
    @State private var showEmailLogin = false
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        ZStack {
            TrimDesignSystem.Colors.background.ignoresSafeArea()
            RadialGradient(gradient: Gradient(colors: [Color.white.opacity(0.03), Color.clear]), center: .top, startRadius: 0, endRadius: 600)
                .ignoresSafeArea()
            
            VStack(spacing: TrimDesignSystem.Spacing.xl) {
                Spacer()
                
                // Brand Header
                VStack(spacing: TrimDesignSystem.Spacing.m) {
                    HStack(spacing: TrimDesignSystem.Spacing.s) {
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 48)
                        
                        Text("TRIM")
                            .font(.system(size: 48, weight: .heavy, design: .default))
                            .kerning(2.0)
                            .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                    }
                    
                    Text("Secure access to your finances.")
                        .font(TrimDesignSystem.Typography.body)
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                if showEmailLogin {
                    emailLoginForm
                } else {
                    authOptions
                }
            }
            .padding(TrimDesignSystem.Spacing.xl)
            
            if authService.isLoading {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: TrimDesignSystem.Colors.accentPrimary))
                    .scaleEffect(1.5)
            }
        }
    }
    
    // MARK: - Auth Options
    private var authOptions: View {
        VStack(spacing: TrimDesignSystem.Spacing.l) {
            
            if let error = authService.authError {
                Text(error)
                    .font(TrimDesignSystem.Typography.caption)
                    .foregroundColor(TrimDesignSystem.Colors.warning)
            }
            
            // Sign in with Apple
            Button(action: {
                // Simulating Apple Auth flow
                authService.signInWithApple(identityToken: "mock_id_token", authCode: "mock_auth_code")
            }) {
                HStack(spacing: TrimDesignSystem.Spacing.m) {
                    Image(systemName: "applelogo")
                        .font(.system(size: 20))
                    Text("Continue with Apple")
                        .font(TrimDesignSystem.Typography.subheader)
                }
                .foregroundColor(TrimDesignSystem.Colors.background)
                .frame(maxWidth: .infinity)
                .padding()
                .background(TrimDesignSystem.Colors.textPrimary)
                .cornerRadius(TrimDesignSystem.Radius.medium)
            }
            .trimPressAnimation()
            
            // Sign in with Google
            Button(action: {
                // Simulating Google Auth flow
                authService.signInWithGoogle(idToken: "mock_google_token")
            }) {
                HStack(spacing: TrimDesignSystem.Spacing.m) {
                    Image(systemName: "g.circle.fill")
                        .font(.system(size: 20))
                    Text("Continue with Google")
                        .font(TrimDesignSystem.Typography.subheader)
                }
                .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(TrimDesignSystem.Colors.surface.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: TrimDesignSystem.Radius.medium)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .cornerRadius(TrimDesignSystem.Radius.medium)
            }
            .trimPressAnimation()
            
            Button(action: {
                withAnimation {
                    showEmailLogin = true
                }
            }) {
                Text("Continue with Email")
                    .font(TrimDesignSystem.Typography.body)
                    .foregroundColor(TrimDesignSystem.Colors.textSecondary)
            }
            .padding(.top, TrimDesignSystem.Spacing.m)
        }
    }
    
    // MARK: - Email Login Form
    private var emailLoginForm: View {
        VStack(spacing: TrimDesignSystem.Spacing.l) {
            
            if let error = authService.authError {
                Text(error)
                    .font(TrimDesignSystem.Typography.caption)
                    .foregroundColor(TrimDesignSystem.Colors.warning)
            }
            
            GlassCard {
                VStack(spacing: TrimDesignSystem.Spacing.m) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .font(TrimDesignSystem.Typography.body)
                        .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                        .padding()
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(TrimDesignSystem.Radius.small)
                    
                    SecureField("Password", text: $password)
                        .font(TrimDesignSystem.Typography.body)
                        .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                        .padding()
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(TrimDesignSystem.Radius.small)
                }
            }
            
            Button(action: {
                authService.signInWithEmail(email: email, password: password)
            }) {
                Text("Sign In")
                    .font(TrimDesignSystem.Typography.subheader)
                    .foregroundColor(TrimDesignSystem.Colors.background)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(TrimDesignSystem.Colors.accentPrimary)
                    .cornerRadius(TrimDesignSystem.Radius.medium)
            }
            .trimPressAnimation()
            
            Button(action: {
                withAnimation {
                    showEmailLogin = false
                }
            }) {
                Text("Back to options")
                    .font(TrimDesignSystem.Typography.caption)
                    .foregroundColor(TrimDesignSystem.Colors.textSecondary)
            }
        }
    }
}
