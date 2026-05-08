import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @FocusState private var focusedEmail: Bool
    
    let onBackToLogin: () -> Void
    
    @State private var email: String = ""
    @State private var didSend: Bool = false
    
    var body: some View {
        ZStack {
            TrimDesignSystem.Colors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: TrimDesignSystem.Spacing.xl) {
                    header
                    
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(TrimDesignSystem.Typography.caption)
                                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                            
                            TextField("", text: $email)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.emailAddress)
                                .textContentType(.username)
                                .submitLabel(.send)
                                .focused($focusedEmail)
                                .font(TrimDesignSystem.Typography.body)
                                .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                                .padding(.horizontal, TrimDesignSystem.Spacing.m)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: TrimDesignSystem.Radius.small, style: .continuous)
                                        .fill(Color.black.opacity(0.22))
                                )
                        }
                    }
                    
                    if didSend {
                        successBanner(text: "Password reset email sent. Check your inbox.")
                    } else if let errorMessage = authViewModel.errorMessage {
                        errorBanner(text: errorMessage)
                    }
                    
                    Button {
                        focusedEmail = false
                        Task {
                            didSend = false
                            await authViewModel.sendPasswordReset(email: email)
                            if authViewModel.errorMessage == nil {
                                didSend = true
                            }
                        }
                    } label: {
                        HStack(spacing: TrimDesignSystem.Spacing.s) {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(TrimDesignSystem.Colors.background)
                            }
                            Text("Send Reset Email")
                                .font(TrimDesignSystem.Typography.subheader)
                        }
                        .foregroundColor(TrimDesignSystem.Colors.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, TrimDesignSystem.Spacing.m)
                        .background(
                            RoundedRectangle(cornerRadius: TrimDesignSystem.Radius.medium, style: .continuous)
                                .fill(TrimDesignSystem.Colors.accentPrimary)
                        )
                    }
                    .trimPressAnimation()
                    .disabled(!canSubmit || authViewModel.isLoading)
                    .opacity((!canSubmit || authViewModel.isLoading) ? 0.5 : 1.0)
                    
                    Button {
                        focusedEmail = false
                        onBackToLogin()
                    } label: {
                        Text("Back to Sign In")
                            .font(TrimDesignSystem.Typography.body)
                            .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                    }
                    .disabled(authViewModel.isLoading)
                    
                    Spacer(minLength: 0)
                }
                .padding(TrimDesignSystem.Spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            authViewModel.clearError()
            didSend = false
        }
        .onSubmit {
            if canSubmit && !authViewModel.isLoading {
                Task {
                    didSend = false
                    await authViewModel.sendPasswordReset(email: email)
                    if authViewModel.errorMessage == nil {
                        didSend = true
                    }
                }
            }
        }
    }
    
    private var canSubmit: Bool {
        authViewModel.isValidEmail(email)
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Reset your password")
                .font(TrimDesignSystem.Typography.header)
                .foregroundColor(TrimDesignSystem.Colors.textPrimary)
            
            Text("We’ll email you a secure reset link.")
                .font(TrimDesignSystem.Typography.body)
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
        }
    }
    
    private func errorBanner(text: String) -> some View {
        HStack(spacing: TrimDesignSystem.Spacing.s) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
            Text(text)
                .font(TrimDesignSystem.Typography.caption)
                .multilineTextAlignment(.leading)
        }
        .foregroundColor(TrimDesignSystem.Colors.error)
        .padding(.horizontal, TrimDesignSystem.Spacing.m)
        .padding(.vertical, TrimDesignSystem.Spacing.s)
        .background(
            RoundedRectangle(cornerRadius: TrimDesignSystem.Radius.small, style: .continuous)
                .fill(TrimDesignSystem.Colors.error.opacity(0.08))
        )
    }
    
    private func successBanner(text: String) -> some View {
        HStack(spacing: TrimDesignSystem.Spacing.s) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
            Text(text)
                .font(TrimDesignSystem.Typography.caption)
                .multilineTextAlignment(.leading)
        }
        .foregroundColor(TrimDesignSystem.Colors.success)
        .padding(.horizontal, TrimDesignSystem.Spacing.m)
        .padding(.vertical, TrimDesignSystem.Spacing.s)
        .background(
            RoundedRectangle(cornerRadius: TrimDesignSystem.Radius.small, style: .continuous)
                .fill(TrimDesignSystem.Colors.success.opacity(0.10))
        )
    }
}
