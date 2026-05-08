import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @FocusState private var focusedField: Field?
    
    let onCreateAccount: () -> Void
    let onForgotPassword: () -> Void
    
    @State private var email: String = ""
    @State private var password: String = ""
    
    enum Field: Hashable {
        case email
        case password
    }
    
    var body: some View {
        ZStack {
            TrimDesignSystem.Colors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: TrimDesignSystem.Spacing.xl) {
                    header
                    
                    GlassCard {
                        VStack(spacing: TrimDesignSystem.Spacing.m) {
                            inputField(
                                title: "Email",
                                text: $email,
                                keyboardType: .emailAddress,
                                contentType: .username,
                                textInputAutocapitalization: .never,
                                submitLabel: .next,
                                focused: .email
                            )
                            
                            secureField(
                                title: "Password",
                                text: $password,
                                contentType: .password,
                                submitLabel: .go,
                                focused: .password
                            )
                        }
                    }
                    
                    if let errorMessage = authViewModel.errorMessage {
                        errorBanner(text: errorMessage)
                    }
                    
                    Button {
                        focusedField = nil
                        Task { await authViewModel.signIn(email: email, password: password) }
                    } label: {
                        HStack(spacing: TrimDesignSystem.Spacing.s) {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(TrimDesignSystem.Colors.background)
                            }
                            Text("Sign In")
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
                    
                    VStack(spacing: TrimDesignSystem.Spacing.s) {
                        Button {
                            focusedField = nil
                            onForgotPassword()
                        } label: {
                            Text("Forgot password?")
                                .font(TrimDesignSystem.Typography.body)
                                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                        }
                        .disabled(authViewModel.isLoading)
                        
                        Button {
                            focusedField = nil
                            onCreateAccount()
                        } label: {
                            HStack(spacing: 6) {
                                Text("New to Trim?")
                                    .font(TrimDesignSystem.Typography.body)
                                    .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                                Text("Create an account")
                                    .font(TrimDesignSystem.Typography.body)
                                    .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
                            }
                        }
                        .disabled(authViewModel.isLoading)
                    }
                    .padding(.top, 4)
                    
                    Spacer(minLength: 0)
                }
                .padding(TrimDesignSystem.Spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            authViewModel.clearError()
        }
        .onSubmit {
            switch focusedField {
            case .email:
                focusedField = .password
            case .password:
                if canSubmit && !authViewModel.isLoading {
                    focusedField = nil
                    Task { await authViewModel.signIn(email: email, password: password) }
                }
            case nil:
                break
            }
        }
    }
    
    private var canSubmit: Bool {
        authViewModel.isValidEmail(email) && !password.isEmpty
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: TrimDesignSystem.Spacing.s) {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                
                Text("Trim")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundColor(TrimDesignSystem.Colors.textPrimary)
            }
            
            Text("Sign in to continue.")
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
    
    private func inputField(
        title: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType,
        contentType: UITextContentType?,
        textInputAutocapitalization: TextInputAutocapitalization,
        submitLabel: SubmitLabel,
        focused: Field
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(TrimDesignSystem.Typography.caption)
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
            
            TextField("", text: text)
                .textInputAutocapitalization(textInputAutocapitalization)
                .autocorrectionDisabled()
                .keyboardType(keyboardType)
                .textContentType(contentType)
                .submitLabel(submitLabel)
                .focused($focusedField, equals: focused)
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
    
    private func secureField(
        title: String,
        text: Binding<String>,
        contentType: UITextContentType?,
        submitLabel: SubmitLabel,
        focused: Field
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(TrimDesignSystem.Typography.caption)
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
            
            SecureField("", text: text)
                .textContentType(contentType)
                .submitLabel(submitLabel)
                .focused($focusedField, equals: focused)
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
}
