import SwiftUI

struct NegotiationWorkflowView: View {
    let insight: FinancialInsight
    @Environment(\.dismiss) var dismiss
    
    @State private var currentStep = 1
    @State private var userIntent: String?
    @State private var plan: (strategy: NegotiationStrategy, script: NegotiationScript)?
    @State private var savedAmount: String = ""
    
    var body: some View {
        SecureView {
            ZStack {
                TrimDesignSystem.Colors.background.ignoresSafeArea()
                
                VStack(spacing: TrimDesignSystem.Spacing.xl) {
                    header
                    
                    if currentStep == 1 {
                        contextStep
                    } else if currentStep == 2 {
                        intentStep
                    } else if currentStep == 3 {
                        actionStep
                    } else {
                        outcomeStep
                    }
                    
                    Spacer()
                    
                    navigationButtons
                }
                .padding(TrimDesignSystem.Spacing.l)
            }
            .onAppear {
                plan = NegotiationEngine.shared.generateNegotiationPlan(for: insight)
            }
        }
    }
    
    private var header: some View {
        HStack {
            Text("Negotiation Guide")
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
            Button("Cancel") { dismiss() }
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
        }
    }
    
    // MARK: - Steps
    
    private var contextStep: some View {
        VStack(spacing: 20) {
            Text("Why Negotiate?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            PremiumGlassCard {
                VStack(spacing: 16) {
                    HStack {
                        Text("Current Monthly")
                            .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                        Spacer()
                        Text("$\(String(format: "%.2f", insight.monthlyImpact))")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Text("Annual Impact")
                            .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                        Spacer()
                        Text("$\(String(format: "%.2f", insight.annualImpact))")
                            .fontWeight(.bold)
                            .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
                    }
                }
            }
            
            Text("This provider frequently offers discounts to users who ask. We've identified a 70% chance of success.")
                .font(.subheadline)
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var intentStep: some View {
        VStack(spacing: 20) {
            Text("What's your goal?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                IntentButton(title: "Lower my monthly bill", isSelected: userIntent == "lower") { userIntent = "lower" }
                IntentButton(title: "Cancel this subscription", isSelected: userIntent == "cancel") { userIntent = "cancel" }
                IntentButton(title: "Explore other options", isSelected: userIntent == "explore") { userIntent = "explore" }
            }
        }
    }
    
    private var actionStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let plan = plan {
                Text("Recommended Strategy")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
                
                Text(plan.strategy.rawValue)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                PremiumGlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("YOUR SCRIPT")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                        
                        Text("\"\(plan.script.script)\"")
                            .font(.system(size: 14, weight: .medium))
                            .italic()
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                        
                        Text("KEY TALKING POINTS")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                            .padding(.top, 8)
                        
                        ForEach(plan.script.talkingPoints, id: \.self) { point in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
                                Text(point)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var outcomeStep: some View {
        VStack(spacing: 24) {
            Text("Did you save money?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                Button("Yes, I saved!") {
                    // Track success
                }
                .padding()
                .background(TrimDesignSystem.Colors.accentPrimary)
                .foregroundColor(.black)
                .cornerRadius(TrimDesignSystem.Radius.medium)
                
                Button("No luck today") {
                    dismiss()
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .foregroundColor(.white)
                .cornerRadius(TrimDesignSystem.Radius.medium)
            }
            
            if true { // Simplified for the mock
                VStack(spacing: 8) {
                    Text("How much did you save per month?")
                        .font(.caption)
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                    
                    TextField("$0.00", text: $savedAmount)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    private var navigationButtons: some View {
        HStack {
            if currentStep > 1 {
                Button("Back") { currentStep -= 1 }
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Button(currentStep == 4 ? "Done" : "Next") {
                if currentStep < 4 {
                    currentStep += 1
                } else {
                    dismiss()
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 12)
            .background(TrimDesignSystem.Colors.accentPrimary)
            .foregroundColor(.black)
            .cornerRadius(TrimDesignSystem.Radius.medium)
            .disabled(currentStep == 2 && userIntent == nil)
        }
    }
}

struct IntentButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isSelected ? TrimDesignSystem.Colors.accentPrimary : Color.white.opacity(0.05))
                .foregroundColor(isSelected ? .black : .white)
                .cornerRadius(TrimDesignSystem.Radius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: TrimDesignSystem.Radius.medium)
                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
}
