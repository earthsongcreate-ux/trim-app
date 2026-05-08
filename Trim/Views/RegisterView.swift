import SwiftUI

struct RegisterView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @FocusState private var focusedField: Field?
    
    let onBackToLogin: () -> Void
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    enum Field: Hashable {
        case email
        case password
        case confirmPassword
    }
    
    var body: some View {
        ZStack {
            TrimDesignSystem.Colors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: TrimDesignSystem.Spacing.xl) {
                    header
                    
                    PremiumGlassCard(.inset) {
                        VStack(spacing: TrimDesignSystem.Spacing.m) {
                            labeledField(
                                title: "Email",
                                content: AnyView(
                                    TextField("", text: $email)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .keyboardType(.emailAddress)
                                        .textContentType(.username)
                                        .submitLabel(.next)
                                        .focused($focusedField, equals: .email)
                                )
                            )
                            
                            labeledField(
                                title: "Password",
                                content: AnyView(
                                    SecureField("", text: $password)
                                        .textContentType(.newPassword)
                                        .submitLabel(.next)
                                        .focused($focusedField, equals: .password)
                                )
                            )
                            
                            labeledField(
                                title: "Confirm Password",
                                content: AnyView(
                                    SecureField("", text: $confirmPassword)
                                        .textContentType(.newPassword)
                                        .submitLabel(.go)
                                        .focused($focusedField, equals: .confirmPassword)
                                )
                            )
                        }
                    }
                    
                    if let errorMessage = inlineErrorMessage {
                        errorBanner(text: errorMessage)
                    } else if let errorMessage = authViewModel.errorMessage {
                        errorBanner(text: errorMessage)
                    }
                    
                    Button {
                        focusedField = nil
                        Task { await authViewModel.signUp(email: email, password: password) }
                    } label: {
                        HStack(spacing: TrimDesignSystem.Spacing.s) {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(TrimDesignSystem.Colors.background)
                            }
                            Text("Create Account")
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
                        focusedField = nil
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
        .onAppear { authViewModel.clearError() }
        .onSubmit {
            switch focusedField {
            case .email:
                focusedField = .password
            case .password:
                focusedField = .confirmPassword
            case .confirmPassword:
                if canSubmit && !authViewModel.isLoading {
                    focusedField = nil
                    Task { await authViewModel.signUp(email: email, password: password) }
                }
            case nil:
                break
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Create your account")
                .font(TrimDesignSystem.Typography.header)
                .foregroundColor(TrimDesignSystem.Colors.textPrimary)
            
            Text("Secure, private, and built for clarity.")
                .font(TrimDesignSystem.Typography.body)
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
        }
    }
    
    private var inlineErrorMessage: String? {
        if !confirmPassword.isEmpty && password != confirmPassword {
            return "Passwords don’t match."
        }
        return nil
    }
    
    private var canSubmit: Bool {
        authViewModel.isValidEmail(email) && password.count >= 6 && password == confirmPassword
    }
    
    private func labeledField(title: String, content: AnyView) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(TrimDesignSystem.Typography.caption)
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
            
            content
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
}
