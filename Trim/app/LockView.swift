import SwiftUI

// MARK: - LockView

/// Minimal lock screen displayed when the app requires authentication.
///
/// Automatically triggers biometric auth on appear. Provides a manual
/// retry button and surfaces auth errors inline. Reads `BiometricAuthManager`
/// from the environment — no direct coupling to `SessionManager`.
struct LockView: View {
    
    @EnvironmentObject var authManager: BiometricAuthManager
    
    /// Subtle pulse for the lock icon.
    @State private var isPulsing = false
    
    /// Prevents duplicate auth prompts during the system dialog lifecycle.
    @State private var isAuthenticating = false
    
    var body: some View {
        ZStack {
            // Background — #0F172A
            TrimDesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                lockIcon
                    .padding(.bottom, TrimDesignSystem.Spacing.xl)
                
                title
                    .padding(.bottom, TrimDesignSystem.Spacing.s)
                
                subtitle
                
                // Error banner — only when an error exists
                if !authManager.authError.isEmpty {
                    errorMessage
                        .padding(.top, TrimDesignSystem.Spacing.l)
                }
                
                Spacer()
                
                unlockButton
                    .padding(.bottom, TrimDesignSystem.Spacing.m)
                
                // Trust microcopy
                HStack(spacing: TrimDesignSystem.Spacing.xs) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 11))
                    Text("Protected by Face ID")
                        .font(.system(size: 12))
                }
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                .padding(.bottom, TrimDesignSystem.Spacing.xl)
            }
            .padding(.horizontal, TrimDesignSystem.Spacing.l)
        }
        // Auto-trigger on appear
        .onAppear {
            triggerAuth()
        }
    }
    
    // MARK: - Lock Icon
    
    private var lockIcon: some View {
        Image(systemName: "lock.shield.fill")
            .font(.system(size: 64, weight: .thin))
            .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
            .scaleEffect(isPulsing ? 1.06 : 1.0)
            .opacity(isPulsing ? 0.75 : 1.0)
            .animation(
                .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear { isPulsing = true }
    }
    
    // MARK: - Title
    
    private var title: some View {
        Text("Secure Access")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(TrimDesignSystem.Colors.textPrimary)
    }
    
    // MARK: - Subtitle
    
    private var subtitle: some View {
        Text("Authenticate to access your financial data")
            .font(.subheadline)
            .foregroundColor(TrimDesignSystem.Colors.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, TrimDesignSystem.Spacing.xl)
    }
    
    // MARK: - Error Message
    
    private var errorMessage: some View {
        HStack(spacing: TrimDesignSystem.Spacing.s) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
            
            Text(authManager.authError)
                .font(.caption)
                .multilineTextAlignment(.leading)
        }
        .foregroundColor(TrimDesignSystem.Colors.error)
        .padding(.horizontal, TrimDesignSystem.Spacing.m)
        .padding(.vertical, TrimDesignSystem.Spacing.s)
        .background(
            RoundedRectangle(cornerRadius: TrimDesignSystem.Radius.small)
                .fill(TrimDesignSystem.Colors.error.opacity(0.08))
        )
        .transition(.opacity)
    }
    
    // MARK: - Unlock Button
    
    private var unlockButton: some View {
        Button(action: { triggerAuth() }) {
            HStack(spacing: TrimDesignSystem.Spacing.s) {
                Image(systemName: "faceid")
                    .font(.body.weight(.medium))
                
                Text("Unlock with Face ID")
                    .font(.headline)
            }
            .foregroundColor(TrimDesignSystem.Colors.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, TrimDesignSystem.Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: TrimDesignSystem.Radius.medium)
                    .fill(TrimDesignSystem.Colors.accentPrimary)
            )
        }
        .disabled(isAuthenticating)
        .opacity(isAuthenticating ? 0.5 : 1.0)
        .padding(.horizontal, TrimDesignSystem.Spacing.l)
    }
    
    // MARK: - Auth Trigger
    
    private func triggerAuth() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        authManager.authenticate()
        
        // Release the guard after the system dialog cycle completes.
        // This covers both success and failure paths.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isAuthenticating = false
        }
    }
}
