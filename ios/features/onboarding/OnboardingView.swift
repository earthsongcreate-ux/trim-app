import SwiftUI

enum OnboardingStep {
    case intro
    case personalization
    case bankConnection
    case liveScan
    case insight
    case paywall
}

struct OnboardingView: View {
    @State private var currentStep: OnboardingStep = .intro
    @State private var scanProgress: CGFloat = 0.0
    @State private var isScanning = false
    @State private var selectedGoal: String? = nil
    
    var body: some View {
        ZStack {
            TrimDesignSystem.Colors.background.ignoresSafeArea()
            RadialGradient(gradient: Gradient(colors: [Color.white.opacity(0.03), Color.clear]), center: .center, startRadius: 0, endRadius: 500)
                .ignoresSafeArea()
            
            VStack {
                switch currentStep {
                case .intro:
                    introStep
                case .personalization:
                    personalizationStep
                case .bankConnection:
                    bankConnectionStep
                case .liveScan:
                    liveScanStep
                case .insight:
                    insightStep
                case .paywall:
                    paywallStep
                }
            }
            .padding(TrimDesignSystem.Spacing.m)
            .animation(.easeInOut(duration: 0.3), value: currentStep)
        }
    }
    
    // MARK: - 1. Intro Step
    private var introStep: View {
        VStack(spacing: TrimDesignSystem.Spacing.xl) {
            Spacer()
            
            HStack(spacing: TrimDesignSystem.Spacing.s) {
                Image(systemName: "f.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
                Text("TRIM")
                    .font(.system(size: 32, weight: .heavy, design: .default))
                    .kerning(1.5)
                    .foregroundColor(TrimDesignSystem.Colors.textPrimary)
            }
            
            Text("Intelligence for your money.")
                .font(TrimDesignSystem.Typography.header)
                .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Identify wasted spending and lower your bills automatically.")
                .font(TrimDesignSystem.Typography.body)
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button(action: { currentStep = .personalization }) {
                Text("Get Started")
                    .font(TrimDesignSystem.Typography.subheader)
                    .foregroundColor(TrimDesignSystem.Colors.background)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(TrimDesignSystem.Colors.accentPrimary)
                    .cornerRadius(TrimDesignSystem.Radius.medium)
            }
            .trimPressAnimation()
        }
    }
    
    // MARK: - 2. Personalization Step
    private var personalizationStep: View {
        VStack(spacing: TrimDesignSystem.Spacing.l) {
            Spacer()
            
            Text("What's your primary goal?")
                .font(TrimDesignSystem.Typography.header)
                .foregroundColor(TrimDesignSystem.Colors.textPrimary)
            
            VStack(spacing: TrimDesignSystem.Spacing.m) {
                goalOption(title: "Cancel Unused Subscriptions", icon: "xmark.circle")
                goalOption(title: "Lower Recurring Bills", icon: "arrow.down.circle")
                goalOption(title: "Track & Categorize Spending", icon: "chart.pie")
            }
            
            Spacer()
        }
    }
    
    private func goalOption(title: String, icon: String) -> some View {
        Button(action: {
            selectedGoal = title
            currentStep = .bankConnection
        }) {
            GlassCard {
                HStack(spacing: TrimDesignSystem.Spacing.m) {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                    
                    Text(title)
                        .font(TrimDesignSystem.Typography.body)
                        .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                    
                    Spacer()
                }
            }
        }
        .trimPressAnimation()
    }
    
    // MARK: - 3. Bank Connection Step
    private var bankConnectionStep: View {
        VStack(spacing: TrimDesignSystem.Spacing.xl) {
            Spacer()
            
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
            
            VStack(spacing: TrimDesignSystem.Spacing.s) {
                Text("Secure Bank Connection")
                    .font(TrimDesignSystem.Typography.header)
                    .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                
                Text("Trim uses Plaid to securely read your transactions. We never store your credentials.")
                    .font(TrimDesignSystem.Typography.body)
                    .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            GlassCard {
                VStack(alignment: .leading, spacing: TrimDesignSystem.Spacing.m) {
                    trustRow(icon: "checkmark.circle.fill", text: "256-bit encryption")
                    trustRow(icon: "checkmark.circle.fill", text: "Read-only access")
                    trustRow(icon: "checkmark.circle.fill", text: "Disconnect anytime")
                }
            }
            
            Spacer()
            
            Button(action: {
                currentStep = .liveScan
                simulateScan()
            }) {
                Text("Connect Securely")
                    .font(TrimDesignSystem.Typography.subheader)
                    .foregroundColor(TrimDesignSystem.Colors.background)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(TrimDesignSystem.Colors.accentPrimary)
                    .cornerRadius(TrimDesignSystem.Radius.medium)
            }
            .trimPressAnimation()
        }
    }
    
    private func trustRow(icon: String, text: String) -> some View {
        HStack(spacing: TrimDesignSystem.Spacing.m) {
            Image(systemName: icon)
                .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
            Text(text)
                .font(TrimDesignSystem.Typography.body)
                .foregroundColor(TrimDesignSystem.Colors.textPrimary)
        }
    }
    
    // MARK: - 4. Live Scan Step
    private var liveScanStep: View {
        VStack(spacing: TrimDesignSystem.Spacing.xl) {
            Spacer()
            
            ZStack {
                // Base track
                Circle()
                    .stroke(Color.black.opacity(0.4), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .shadow(color: .black.opacity(0.6), radius: 6, x: 4, y: 4)
                    .shadow(color: .white.opacity(0.05), radius: 2, x: -1, y: -1)
                
                // Active stroke
                Circle()
                    .trim(from: 0, to: scanProgress)
                    .stroke(TrimDesignSystem.Colors.accentPrimary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: TrimDesignSystem.Colors.glowPrimary, radius: 2, x: 0, y: 0)
                    .overlay(
                        Circle()
                            .trim(from: max(0, scanProgress - 0.02), to: scanProgress)
                            .stroke(TrimDesignSystem.Colors.edgePrimary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    )
                
                VStack(spacing: TrimDesignSystem.Spacing.xs) {
                    Text("\(Int(scanProgress * 100))%")
                        .font(TrimDesignSystem.Typography.header)
                        .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                    Text("Scanning...")
                        .font(TrimDesignSystem.Typography.caption)
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                }
            }
            .frame(width: 200, height: 200)
            .padding(TrimDesignSystem.Spacing.l)
            .background(
                RadialGradient(gradient: Gradient(colors: [Color.black.opacity(0.3), Color.black.opacity(0.1)]), center: .center, startRadius: 0, endRadius: 100)
            )
            .cornerRadius(100)
            .overlay(
                RoundedRectangle(cornerRadius: 100)
                    .stroke(Color.black.opacity(0.7), lineWidth: 8)
                    .blur(radius: 6)
                    .offset(x: 6, y: 6)
                    .mask(RoundedRectangle(cornerRadius: 100).fill(LinearGradient(Color.black, Color.clear)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 100)
                    .stroke(Color.white.opacity(0.08), lineWidth: 2)
                    .blur(radius: 2)
                    .offset(x: -1, y: -1)
                    .mask(RoundedRectangle(cornerRadius: 100).fill(LinearGradient(Color.clear, Color.black)))
            )
            
            Text("Analyzing 3,241 transactions...")
                .font(TrimDesignSystem.Typography.body)
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
            
            Spacer()
        }
    }
    
    private func simulateScan() {
        isScanning = true
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            withAnimation(.linear(duration: 0.05)) {
                scanProgress += 0.02
            }
            if scanProgress >= 1.0 {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    currentStep = .insight
                }
            }
        }
    }
    
    // MARK: - 5. Insight Step
    private var insightStep: View {
        VStack(spacing: TrimDesignSystem.Spacing.xl) {
            Spacer()
            
            VStack(spacing: TrimDesignSystem.Spacing.s) {
                Text("Scan Complete")
                    .font(TrimDesignSystem.Typography.caption)
                    .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
                    .kerning(1.0)
                
                Text("We found savings.")
                    .font(TrimDesignSystem.Typography.header)
                    .foregroundColor(TrimDesignSystem.Colors.textPrimary)
            }
            
            GlassCard {
                VStack(spacing: TrimDesignSystem.Spacing.l) {
                    Text("$842")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                        .shadow(color: TrimDesignSystem.Colors.glowPrimary, radius: 4, x: 0, y: 0)
                    
                    Text("in potential annual savings identified across 4 unused subscriptions and 2 bill negotiations.")
                        .font(TrimDesignSystem.Typography.body)
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
            
            Button(action: { currentStep = .paywall }) {
                Text("Reveal & Claim Savings")
                    .font(TrimDesignSystem.Typography.subheader)
                    .foregroundColor(TrimDesignSystem.Colors.background)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(TrimDesignSystem.Colors.accentPrimary)
                    .cornerRadius(TrimDesignSystem.Radius.medium)
            }
            .trimPressAnimation()
        }
    }
    
    // MARK: - 6. Paywall Step
    private var paywallStep: View {
        // Integrate with the actual PaywallView
        PaywallView(
            paywallData: PaywallData(
                type: "soft",
                trigger: "onboarding",
                content: PaywallContent(
                    headline: "Unlock Trim IQ",
                    subtext: "Let us cancel those 4 unused subscriptions and negotiate your bills automatically.",
                    pricing: PricingOptions(monthly: 7.99, annual: 69.99),
                    primaryCta: "Start 3-Day Free Trial",
                    secondaryCta: "Maybe Later"
                )
            ),
            onDismiss: {
                // Route to main dashboard
                print("Proceed to Dashboard")
            },
            onConvert: {
                // Handle conversion
                print("User Subscribed")
            }
        )
    }
}

