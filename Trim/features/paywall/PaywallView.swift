import SwiftUI

struct PaywallView: View {
    let paywallData: PaywallData
    var onDismiss: () -> Void
    var onConvert: () -> Void
    
    var dynamicSavings: Double = 842.0 // Mocked for dynamic ROI anchor
    
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var selectedPlan: SubscriptionPlan = .annual
    @State private var offerState: FoundingAnnualOfferState?
    @State private var isStartingTrial: Bool = false
    @State private var localErrorMessage: String?
    
    var isHardPaywall: Bool {
        return paywallData.type == "hard"
    }

    var body: some View {
        ZStack {
            TrimDesignSystem.Colors.background.ignoresSafeArea()
            RadialGradient(gradient: Gradient(colors: [Color.white.opacity(0.04), Color.clear]), center: .top, startRadius: 0, endRadius: 600)
                .ignoresSafeArea()
            
            VStack(spacing: TrimDesignSystem.Spacing.xl) {
                VStack(spacing: TrimDesignSystem.Spacing.s) {
                    Text(paywallData.content.headline)
                        .font(TrimDesignSystem.Typography.header)
                        .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(paywallData.content.subtext)
                        .font(TrimDesignSystem.Typography.body)
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, TrimDesignSystem.Spacing.l)
                .padding(.horizontal)
                
                PremiumGlassCard(.inset) {
                    VStack(alignment: .leading, spacing: TrimDesignSystem.Spacing.m) {
                        timelineRow(
                            title: "Today",
                            detail: "$0",
                            icon: "sparkles"
                        )
                        timelineRow(
                            title: "Day \(max(paywallData.content.pricing.trialDays - 1, 1))",
                            detail: "Reminder",
                            icon: "bell"
                        )
                        timelineRow(
                            title: "Day \(paywallData.content.pricing.trialDays)",
                            detail: "\(formattedMonthly) / month or \(formattedAnnual) / year",
                            icon: "lock.open"
                        )
                        
                        Text("Cancel anytime in Settings.")
                            .font(TrimDesignSystem.Typography.caption)
                            .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                            .padding(.top, 2)
                    }
                }
                .padding(.horizontal)
                
                PremiumGlassCard {
                    VStack(spacing: TrimDesignSystem.Spacing.xs) {
                        Text("Savings found")
                            .font(TrimDesignSystem.Typography.caption)
                            .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                            .textCase(.uppercase)
                            .kerning(1.0)
                        
                        Text("$\(Int(dynamicSavings)) / yr")
                            .font(.system(size: 52, weight: .bold))
                            .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                            .shadow(color: TrimDesignSystem.Colors.glowPrimary, radius: 3, x: 0, y: 0)
                        
                        Text("based on your scan")
                            .font(TrimDesignSystem.Typography.body)
                            .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                    }
                }
                .padding(.horizontal)
                
                // 2. VALUE SECTION
                PremiumGlassCard(.inset) {
                    VStack(alignment: .leading, spacing: TrimDesignSystem.Spacing.l) {
                        valueRow(icon: "scissors", text: "Cancel unused subscriptions")
                        valueRow(icon: "arrow.down.to.line.alt", text: "Lower recurring bills")
                        valueRow(icon: "checkmark.shield.fill", text: "Keep your data secure")
                    }
                    .padding(.vertical, TrimDesignSystem.Spacing.s)
                }
                .padding(.horizontal)
                
                PremiumGlassCard(.inset) {
                    VStack(alignment: .leading, spacing: TrimDesignSystem.Spacing.m) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Founding Member Bonus")
                                .font(TrimDesignSystem.Typography.subheader)
                                .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                            
                            Spacer()
                            
                            if let offerState, offerState.isAvailable {
                                Text("\(offerState.remainingCount) left")
                                    .font(TrimDesignSystem.Typography.caption)
                                    .foregroundColor(TrimDesignSystem.Colors.accentSecondary)
                            } else {
                                Text("First 250")
                                    .font(TrimDesignSystem.Typography.caption)
                                    .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                            }
                        }
                        
                        Text("Annual members only. Limited-time test offer.")
                            .font(TrimDesignSystem.Typography.caption)
                            .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                        
                        VStack(alignment: .leading, spacing: TrimDesignSystem.Spacing.s) {
                            valueRow(icon: "lock.fill", text: "Lock $99/year forever")
                            valueRow(icon: "seal.fill", text: "Early supporter badge")
                            valueRow(icon: "sparkles", text: "Future premium features included")
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 3. PRICING
                HStack(spacing: TrimDesignSystem.Spacing.m) {
                    pricingCard(
                        title: "Monthly",
                        price: formattedMonthly,
                        period: "/mo",
                        isHighlighted: selectedPlan == .monthly,
                        badges: []
                    )
                    .onTapGesture {
                        selectedPlan = .monthly
                    }
                    
                    pricingCard(
                        title: "Annual",
                        price: formattedAnnual,
                        period: "/yr",
                        isHighlighted: selectedPlan == .annual,
                        badges: ["Recommended", annualSavingsBadge]
                    )
                    .onTapGesture {
                        selectedPlan = .annual
                    }
                }
                .padding(.horizontal)
                
                // 4. CTA
                VStack(spacing: TrimDesignSystem.Spacing.m) {
                    Button(action: {
                        startTrial()
                    }) {
                        HStack(spacing: 10) {
                            if isStartingTrial {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: TrimDesignSystem.Colors.background))
                            }
                            Text(paywallData.content.primaryCta)
                        }
                            .font(TrimDesignSystem.Typography.subheader)
                            .foregroundColor(TrimDesignSystem.Colors.background)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(TrimDesignSystem.Colors.accentPrimary)
                            .cornerRadius(TrimDesignSystem.Radius.medium)
                    }
                    .trimPressAnimation()
                    .disabled(isStartingTrial)
                    
                    if let localErrorMessage {
                        Text(localErrorMessage)
                            .font(TrimDesignSystem.Typography.caption)
                            .foregroundColor(TrimDesignSystem.Colors.error)
                            .multilineTextAlignment(.center)
                    }
                    
                    if !isHardPaywall, let secondaryText = paywallData.content.secondaryCta {
                        Button(action: {
                            onDismiss()
                        }) {
                            Text(secondaryText)
                                .font(TrimDesignSystem.Typography.body)
                                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                        }
                        .trimPressAnimation()
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, TrimDesignSystem.Spacing.xl)
            }
        }
        .interactiveDismissDisabled(isHardPaywall)
        .task {
            await loadOfferState()
        }
    }
    
    private var formattedMonthly: String {
        "$" + String(format: "%.2f", paywallData.content.pricing.monthly)
    }
    
    private var formattedAnnual: String {
        "$" + String(format: "%.2f", paywallData.content.pricing.annual)
    }

    private var annualSavingsBadge: String {
        let monthlyAnnual = paywallData.content.pricing.monthly * 12.0
        guard monthlyAnnual > 0 else { return "Save 0%" }
        let raw = (1.0 - (paywallData.content.pricing.annual / monthlyAnnual)) * 100.0
        let percent = max(Int(raw.rounded()), 0)
        return "Save \(percent)%"
    }
    
    private func valueRow(icon: String, text: String) -> some View {
        HStack(alignment: .center, spacing: TrimDesignSystem.Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
                .frame(width: 24)
            Text(text)
                .font(TrimDesignSystem.Typography.body)
                .foregroundColor(TrimDesignSystem.Colors.textPrimary)
        }
    }
    
    private func timelineRow(title: String, detail: String, icon: String) -> some View {
        HStack(alignment: .center, spacing: TrimDesignSystem.Spacing.m) {
            ZStack {
                Circle()
                    .fill(TrimDesignSystem.Colors.accentSecondary.opacity(0.12))
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(TrimDesignSystem.Colors.accentSecondary)
            }
            .frame(width: 34, height: 34)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TrimDesignSystem.Typography.caption)
                    .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                
                Text(detail)
                    .font(TrimDesignSystem.Typography.body)
                    .foregroundColor(TrimDesignSystem.Colors.textPrimary)
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func pricingCard(title: String, price: String, period: String, isHighlighted: Bool, badges: [String] = []) -> some View {
        PremiumGlassCard(isHighlighted ? .lifted : .inset, cornerRadius: TrimDesignSystem.Radius.medium, padding: 16) {
            VStack(spacing: 8) {
                if !badges.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(badges, id: \.self) { badge in
                            Text(badge)
                                .font(TrimDesignSystem.Typography.caption)
                                .foregroundColor(TrimDesignSystem.Colors.background)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(TrimDesignSystem.Colors.accentPrimary)
                                .cornerRadius(TrimDesignSystem.Radius.medium)
                        }
                    }
                }
                
                Text(title)
                    .font(TrimDesignSystem.Typography.subheader)
                    .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(price)
                        .font(TrimDesignSystem.Typography.header)
                        .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                    
                    Text(period)
                        .font(TrimDesignSystem.Typography.caption)
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                        .padding(.top, 6)
                }
                
                if isHighlighted {
                    Text("Recommended")
                        .font(TrimDesignSystem.Typography.caption)
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                        .padding(.top, 4)
                } else {
                    Text("Flexible monthly plan")
                        .font(TrimDesignSystem.Typography.caption)
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .overlay(
            RoundedRectangle(cornerRadius: TrimDesignSystem.Radius.medium, style: .continuous)
                .stroke(
                    isHighlighted ? TrimDesignSystem.Colors.accentSecondary.opacity(0.45) : Color.white.opacity(0.06),
                    lineWidth: isHighlighted ? 2 : 1
                )
        )
    }
    
    private func loadOfferState() async {
        do {
            offerState = try await UserProfileService.shared.fetchFoundingAnnualOfferState()
        } catch {
            offerState = nil
        }
    }
    
    private func startTrial() {
        guard !isStartingTrial else { return }
        localErrorMessage = nil
        isStartingTrial = true
        
        Task {
            let ok = await authViewModel.startPremiumTrial(plan: selectedPlan)
            await MainActor.run {
                isStartingTrial = false
                if ok {
                    onConvert()
                } else {
                    localErrorMessage = authViewModel.errorMessage ?? "We couldn’t start your trial. Please try again."
                }
            }
        }
    }
}

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
