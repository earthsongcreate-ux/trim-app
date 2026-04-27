import SwiftUI

struct PaywallView: View {
    let paywallData: PaywallData
    var onDismiss: () -> Void
    var onConvert: () -> Void
    
    var dynamicSavings: Double = 842.0 // Mocked for dynamic ROI anchor
    
    var isHardPaywall: Bool {
        return paywallData.type == "hard"
    }

    var body: some View {
        ZStack {
            TrimDesignSystem.Colors.background.ignoresSafeArea()
            RadialGradient(gradient: Gradient(colors: [Color.white.opacity(0.04), Color.clear]), center: .top, startRadius: 0, endRadius: 600)
                .ignoresSafeArea()
            
            VStack(spacing: TrimDesignSystem.Spacing.xl) {
                
                // 1. TOP: Savings Anchor
                VStack(spacing: TrimDesignSystem.Spacing.xs) {
                    Text("You've already identified")
                        .font(TrimDesignSystem.Typography.caption)
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                        .kerning(1.0)
                        .textCase(.uppercase)
                    
                    Text("$\(Int(dynamicSavings))")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                        .shadow(color: TrimDesignSystem.Colors.glowPrimary, radius: 4, x: 0, y: 0)
                    
                    Text("in potential annual savings.")
                        .font(TrimDesignSystem.Typography.body)
                        .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
                }
                .padding(.top, TrimDesignSystem.Spacing.xl)
                
                // 2. VALUE SECTION
                GlassCard {
                    VStack(alignment: .leading, spacing: TrimDesignSystem.Spacing.l) {
                        valueRow(icon: "scissors", text: "Cancel unused subscriptions")
                        valueRow(icon: "arrow.down.to.line.alt", text: "Negotiate lower recurring bills")
                        valueRow(icon: "chart.line.uptrend.xyaxis", text: "Improve financial health")
                    }
                    .padding(.vertical, TrimDesignSystem.Spacing.s)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 3. PRICING
                HStack(spacing: TrimDesignSystem.Spacing.m) {
                    pricingCard(
                        title: "Monthly",
                        price: "$\(paywallData.content.pricing.monthly)",
                        period: "/mo",
                        isHighlighted: false
                    )
                    
                    pricingCard(
                        title: "Annual",
                        price: "$\(paywallData.content.pricing.annual)",
                        period: "/yr",
                        isHighlighted: true,
                        badge: "Best Value"
                    )
                }
                .padding(.horizontal)
                
                // 4. CTA
                VStack(spacing: TrimDesignSystem.Spacing.m) {
                    Button(action: {
                        onConvert()
                    }) {
                        Text(paywallData.content.primaryCta)
                            .font(TrimDesignSystem.Typography.subheader)
                            .foregroundColor(TrimDesignSystem.Colors.background)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(TrimDesignSystem.Colors.accentPrimary)
                            .cornerRadius(TrimDesignSystem.Radius.medium)
                    }
                    .trimPressAnimation()
                    
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
    
    @ViewBuilder
    private func pricingCard(title: String, price: String, period: String, isHighlighted: Bool, badge: String? = nil) -> some View {
        VStack(spacing: 8) {
            if let badge = badge {
                Text(badge)
                    .font(TrimDesignSystem.Typography.caption)
                    .foregroundColor(TrimDesignSystem.Colors.background)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(TrimDesignSystem.Colors.accentPrimary)
                    .cornerRadius(TrimDesignSystem.Radius.medium)
                    .offset(y: -16)
                    .padding(.bottom, -16)
            }
            
            Text(title)
                .font(TrimDesignSystem.Typography.subheader)
                .foregroundColor(isHighlighted ? TrimDesignSystem.Colors.textPrimary : TrimDesignSystem.Colors.textSecondary)
            
            Text(price)
                .font(TrimDesignSystem.Typography.header)
                .foregroundColor(TrimDesignSystem.Colors.textPrimary)
            
            Text(period)
                .font(TrimDesignSystem.Typography.caption)
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, TrimDesignSystem.Spacing.m * 1.5)
        .background(isHighlighted ? TrimDesignSystem.Colors.accentPrimary.opacity(0.1) : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: TrimDesignSystem.Radius.medium)
                .stroke(isHighlighted ? TrimDesignSystem.Colors.accentPrimary : Color.white.opacity(0.08), lineWidth: isHighlighted ? 2 : 1)
        )
        .cornerRadius(TrimDesignSystem.Radius.medium)
        .if(isHighlighted) { view in
            view.background(.ultraThinMaterial)
                .background(TrimDesignSystem.Colors.surface.opacity(0.6))
                .shadow(color: Color.black.opacity(0.4), radius: 12, x: 6, y: 6)
                .shadow(color: Color.white.opacity(0.04), radius: 2, x: -1, y: -1)
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
