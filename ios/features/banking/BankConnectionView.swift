import SwiftUI

// MARK: - BankConnectionView

/// Full-screen modal for connecting bank accounts via Plaid Link.
///
/// Presents a Trim-branded experience around the Plaid Link flow.
/// Handles all states: loading, ready, active, success, and error.
///
/// Usage:
/// ```swift
/// .sheet(isPresented: $showBankConnection) {
///     BankConnectionView()
/// }
/// ```
///
/// The view owns a `PlaidLinkManager` instance as an `@StateObject` to
/// isolate the Link session lifecycle from the parent view.
struct BankConnectionView: View {
    
    @StateObject private var plaidManager = PlaidLinkManager.shared
    @Environment(\.dismiss) private var dismiss
    
    /// Controls whether the Plaid Link UIKit bridge is presented.
    @State private var showPlaidLink = false
    
    /// Tracks backend token exchange progress.
    @State private var isExchanging = false
    
    var body: some View {
        ZStack {
            TrimDesignSystem.Colors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                
                Spacer()
                
                contentForState
                
                Spacer()
                
                footer
            }
            .padding(.horizontal, TrimDesignSystem.Spacing.l)
        }
        .onAppear {
            Task {
                await plaidManager.prepareLinkSession()
            }
        }
        .onDisappear {
            if plaidManager.state != .success {
                plaidManager.reset()
            }
        }
        .sheet(isPresented: $showPlaidLink) {
            PlaidLinkView()
                .environmentObject(plaidManager)
        }
        // Auto-dismiss Plaid sheet when flow completes
        .onChange(of: plaidManager.state) { newState in
            if newState == .success || newState == .exited || newState.isError {
                showPlaidLink = false
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(TrimDesignSystem.Colors.surface)
                    )
            }
        }
        .padding(.top, TrimDesignSystem.Spacing.m)
    }
    
    // MARK: - State Content
    
    @ViewBuilder
    private var contentForState: some View {
        switch plaidManager.state {
        case .idle, .fetchingToken:
            loadingState
        case .ready:
            readyState
        case .active:
            activeState
        case .success:
            successState
        case .exited:
            exitedState
        case .error(let message):
            errorState(message: message)
        }
    }
    
    // MARK: - Loading State
    
    private var loadingState: some View {
        VStack(spacing: TrimDesignSystem.Spacing.l) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: TrimDesignSystem.Colors.accentPrimary))
                .scaleEffect(1.2)
            
            Text("Preparing secure connection...")
                .font(.subheadline)
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
        }
    }
    
    // MARK: - Ready State
    
    private var readyState: some View {
        VStack(spacing: TrimDesignSystem.Spacing.xl) {
            // Icon
            ZStack {
                Circle()
                    .fill(TrimDesignSystem.Colors.accentPrimary.opacity(0.1))
                    .frame(width: 96, height: 96)
                
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 40, weight: .thin))
                    .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
            }
            
            // Title
            VStack(spacing: TrimDesignSystem.Spacing.s) {
                Text("Connect Your Bank")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                
                Text("Securely link your accounts to start finding savings. Your credentials are never stored by Trim.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                    .padding(.horizontal, TrimDesignSystem.Spacing.m)
            }
            
            // Trust indicators
            VStack(spacing: 12) {
                trustRow(icon: "lock.shield.fill", text: "256-bit encryption")
                trustRow(icon: "eye.slash.fill", text: "Credentials never stored")
                trustRow(icon: "building.columns.fill", text: "10,000+ institutions supported")
            }
            .padding(.top, TrimDesignSystem.Spacing.s)
            
            // Connect button
            Button(action: { showPlaidLink = true }) {
                HStack(spacing: TrimDesignSystem.Spacing.s) {
                    Image(systemName: "link")
                        .font(.body.weight(.medium))
                    Text("Connect Bank Account")
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
            .padding(.top, TrimDesignSystem.Spacing.m)
        }
    }
    
    // MARK: - Active State
    
    private var activeState: some View {
        VStack(spacing: TrimDesignSystem.Spacing.l) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: TrimDesignSystem.Colors.accentPrimary))
                .scaleEffect(1.2)
            
            Text("Connecting to your bank...")
                .font(.subheadline)
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
        }
    }
    
    // MARK: - Success State
    
    private var successState: some View {
        VStack(spacing: TrimDesignSystem.Spacing.xl) {
            // Success icon
            ZStack {
                Circle()
                    .fill(TrimDesignSystem.Colors.accentPrimary.opacity(0.1))
                    .frame(width: 96, height: 96)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
            }
            
            VStack(spacing: TrimDesignSystem.Spacing.s) {
                Text("Account Connected")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                
                if let institution = plaidManager.connectedInstitution {
                    Text(institution)
                        .font(.headline)
                        .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
                }
                
                if plaidManager.connectedAccountCount > 0 {
                    Text("\(plaidManager.connectedAccountCount) account\(plaidManager.connectedAccountCount == 1 ? "" : "s") linked")
                        .font(.subheadline)
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                }
            }
            
            // Continue button
            Button(action: {
                Task {
                    isExchanging = true
                    let _ = await plaidManager.sendTokenToBackend()
                    isExchanging = false
                    dismiss()
                }
            }) {
                HStack(spacing: TrimDesignSystem.Spacing.s) {
                    if isExchanging {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: TrimDesignSystem.Colors.background))
                    }
                    Text(isExchanging ? "Finalizing..." : "Continue")
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
            .disabled(isExchanging)
            .opacity(isExchanging ? 0.7 : 1.0)
        }
    }
    
    // MARK: - Exited State
    
    private var exitedState: some View {
        VStack(spacing: TrimDesignSystem.Spacing.xl) {
            Image(systemName: "arrow.uturn.backward.circle")
                .font(.system(size: 48, weight: .thin))
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
            
            VStack(spacing: TrimDesignSystem.Spacing.s) {
                Text("Connection Cancelled")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                
                Text("No accounts were connected. You can try again anytime.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(TrimDesignSystem.Colors.textSecondary)
            }
            
            Button(action: {
                Task { await plaidManager.prepareLinkSession() }
            }) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(TrimDesignSystem.Colors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, TrimDesignSystem.Spacing.m)
                    .background(
                        RoundedRectangle(cornerRadius: TrimDesignSystem.Radius.medium)
                            .fill(TrimDesignSystem.Colors.accentPrimary)
                    )
            }
        }
    }
    
    // MARK: - Error State
    
    private func errorState(message: String) -> some View {
        VStack(spacing: TrimDesignSystem.Spacing.xl) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48, weight: .thin))
                .foregroundColor(TrimDesignSystem.Colors.warning)
            
            VStack(spacing: TrimDesignSystem.Spacing.s) {
                Text("Connection Issue")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                
                Text(message)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(TrimDesignSystem.Colors.textSecondary)
            }
            
            Button(action: {
                Task { await plaidManager.prepareLinkSession() }
            }) {
                Text("Retry")
                    .font(.headline)
                    .foregroundColor(TrimDesignSystem.Colors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, TrimDesignSystem.Spacing.m)
                    .background(
                        RoundedRectangle(cornerRadius: TrimDesignSystem.Radius.medium)
                            .fill(TrimDesignSystem.Colors.accentPrimary)
                    )
            }
        }
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack(spacing: TrimDesignSystem.Spacing.xs) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 11))
            Text("Secured by Plaid. Your credentials are never shared with Trim.")
                .font(.system(size: 12))
        }
        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
        .padding(.bottom, TrimDesignSystem.Spacing.l)
    }
    
    // MARK: - Helpers
    
    private func trustRow(icon: String, text: String) -> some View {
        HStack(spacing: TrimDesignSystem.Spacing.s) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(TrimDesignSystem.Colors.accentPrimary.opacity(0.7))
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
            
            Spacer()
        }
        .padding(.horizontal, TrimDesignSystem.Spacing.xl)
    }
}
