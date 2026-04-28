struct SettingsView: View {
    @EnvironmentObject var authManager: BiometricAuthManager
    @ObservedObject private var currencyService = CurrencyService.shared
    
    @State private var showCurrencyPicker = false
    
    var body: some View {
        ZStack {
            TrimDesignSystem.Colors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: TrimDesignSystem.Spacing.xl) {
                    Text("Settings")
                        .font(TrimDesignSystem.Typography.header)
                        .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                        .padding(.top, 16)
                    
                    currencySection
                    
                    securitySection
                    
                    privacySection
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
        }
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencySelectionView(
                onCurrencySelected: { _ in
                    showCurrencyPicker = false
                },
                isOnboarding: false
            )
        }
    }
    
    // MARK: - Currency Section
    
    private var currencySection: some View {
        VStack(alignment: .leading, spacing: TrimDesignSystem.Spacing.m) {
            Text("Currency")
                .font(TrimDesignSystem.Typography.subheader)
                .foregroundColor(TrimDesignSystem.Colors.textPrimary)
            
            GlassCard {
                VStack(alignment: .leading, spacing: TrimDesignSystem.Spacing.m) {
                    // Current base currency display
                    HStack(spacing: 12) {
                        Text(currencyService.baseCurrency.flag)
                            .font(.system(size: 28))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Base Currency")
                                .font(TrimDesignSystem.Typography.body)
                                .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                            
                            Text("\(currencyService.baseCurrency.name) (\(currencyService.baseCurrency.symbol))")
                                .font(TrimDesignSystem.Typography.caption)
                                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        // Change button
                        Button {
                            showCurrencyPicker = true
                        } label: {
                            Text("Change")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: TrimDesignSystem.Radius.small)
                                        .stroke(TrimDesignSystem.Colors.accentPrimary.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    // Explanation
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: TrimDesignSystem.Spacing.xs) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 11))
                            Text("All transactions are converted to your base currency")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                        
                        HStack(spacing: TrimDesignSystem.Spacing.xs) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11))
                            Text("Exchange rates are locked at time of transaction")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                        
                        HStack(spacing: TrimDesignSystem.Spacing.xs) {
                            Image(systemName: "eye")
                                .font(.system(size: 11))
                            Text("Original currency always visible on foreign transactions")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                    }
                }
            }
        }
    }
    
    private var securitySection: some View {
        VStack(alignment: .leading, spacing: TrimDesignSystem.Spacing.m) {
            Text("Trust & Security")
                .font(TrimDesignSystem.Typography.subheader)
                .foregroundColor(TrimDesignSystem.Colors.textPrimary)
            
            GlassCard {
                VStack(alignment: .leading, spacing: TrimDesignSystem.Spacing.m) {
                    // Biometric status row
                    HStack(spacing: 12) {
                        Image(systemName: "faceid")
                            .font(.system(size: 24))
                            .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Biometric Unlock")
                                .font(TrimDesignSystem.Typography.body)
                                .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                            
                            Text(authManager.biometricType == .none
                                 ? "Not available on this device"
                                 : "Active — \(authManager.biometricType == .faceID ? "Face ID" : "Touch ID")")
                                .font(TrimDesignSystem.Typography.caption)
                                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        // Status badge
                        Image(systemName: authManager.biometricType != .none
                              ? "checkmark.circle.fill"
                              : "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(authManager.biometricType != .none
                                             ? TrimDesignSystem.Colors.accentPrimary
                                             : TrimDesignSystem.Colors.textSecondary)
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    Text("Your financial data stays on your device and is protected by local biometric authentication. Trim never stores your banking credentials.")
                        .font(.caption)
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                        .padding(.top, 4)
                    
                    // Encryption microcopy
                    HStack(spacing: TrimDesignSystem.Spacing.xs) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 11))
                        Text("Your financial data is secured using device-level encryption")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                    .padding(.top, TrimDesignSystem.Spacing.xs)
                }
            }
        }
    }
    
    // MARK: - Privacy Section
    
    private var privacySection: some View {
        VStack(alignment: .leading, spacing: TrimDesignSystem.Spacing.m) {
            Text("Privacy & Security")
                .font(TrimDesignSystem.Typography.subheader)
                .foregroundColor(TrimDesignSystem.Colors.textPrimary)
            
            GlassCard {
                VStack(alignment: .leading, spacing: TrimDesignSystem.Spacing.m) {
                    HStack(spacing: 12) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 24))
                            .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
                        
                        Text("Your financial data stays private and is protected on your device.")
                            .font(.system(size: 13))
                            .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    VStack(alignment: .leading, spacing: 10) {
                        privacyBullet(
                            icon: "iphone.and.arrow.forward",
                            text: "Data processed locally on your device"
                        )
                        privacyBullet(
                            icon: "eye.slash.fill",
                            text: "No third-party tracking or analytics"
                        )
                        privacyBullet(
                            icon: "server.rack",
                            text: "Banking credentials are never stored"
                        )
                    }
                }
            }
        }
    }
    
    private func privacyBullet(icon: String, text: String) -> some View {
        HStack(spacing: TrimDesignSystem.Spacing.s) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(TrimDesignSystem.Colors.accentPrimary.opacity(0.7))
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
        }
    }
}
