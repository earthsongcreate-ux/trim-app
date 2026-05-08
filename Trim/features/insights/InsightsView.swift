import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var authManager: BiometricAuthManager
    
    @State private var insights: [FinancialInsight] = []
    @State private var isLoading = true
    @State private var selectedInsight: FinancialInsight?
    @State private var suppressedCount = 0
    @State private var feedbackStates: [UUID: FeedbackState] = [:]
    
    var body: some View {
        SecureView {
            ZStack {
                TrimDesignSystem.Colors.background.ignoresSafeArea()
                RadialGradient(gradient: Gradient(colors: [Color.white.opacity(0.03), Color.clear]), center: .center, startRadius: 0, endRadius: 500)
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack(alignment: .bottom) {
                        Text("Intelligence Alerts")
                            .font(TrimDesignSystem.Typography.header)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if suppressedCount > 0 {
                            Text("\(suppressedCount) filtered")
                                .font(TrimDesignSystem.Typography.caption)
                                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.06))
                                )
                        }
                    }
                    .padding(.horizontal)
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: TrimDesignSystem.Colors.accentPrimary))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if insights.isEmpty {
                        emptyState
                    } else {
                        insightSummary
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(insights) { insight in
                                    InsightCard(
                                        insight: insight,
                                        feedbackState: feedbackBinding(for: insight.id)
                                    ) {
                                        selectedInsight = insight
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .sheet(item: $selectedInsight) { insight in
                NegotiationWorkflowView(insight: insight)
            }
            .task {
                do {
                    let fetched = try await TrimApiService.shared.fetchInsights()
                    let approved = fetched.filter { $0.showToUser }
                    insights = approved
                    suppressedCount = max(0, fetched.count - approved.count)
                    isLoading = false
                } catch {
                    print("Error: \(error)")
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 48))
                .foregroundColor(TrimDesignSystem.Colors.accentPrimary.opacity(0.5))
            
            Text("All Clear")
                .font(TrimDesignSystem.Typography.subheader)
                .foregroundColor(.white)
            
            Text("No actionable insights right now.\nWe're continuously monitoring your finances.")
                .font(TrimDesignSystem.Typography.body)
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var insightSummary: some View {
        let monthly = insights.reduce(0.0) { $0 + $1.monthlyImpact }
        let annual = insights.reduce(0.0) { $0 + $1.annualImpact }
        
        return PremiumGlassCard {
            HStack(alignment: .center, spacing: TrimDesignSystem.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(TrimDesignSystem.Colors.accentSecondary.opacity(0.12))
                    Circle()
                        .stroke(TrimDesignSystem.Colors.accentSecondary.opacity(0.35), lineWidth: 1)
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(TrimDesignSystem.Colors.accentSecondary)
                }
                .frame(width: 44, height: 44)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(insights.count) alerts ready")
                        .font(TrimDesignSystem.Typography.subheader)
                        .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                    
                    Text("$\(Int(monthly.rounded()))/mo • $\(Int(annual.rounded()))/yr potential impact")
                        .font(TrimDesignSystem.Typography.caption)
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helpers
    
    /// Creates a binding into the feedbackStates dictionary for a given insight ID.
    private func feedbackBinding(for id: UUID) -> Binding<FeedbackState> {
        Binding(
            get: { feedbackStates[id] ?? .none },
            set: { feedbackStates[id] = $0 }
        )
    }
}

struct InsightCard: View {
    let insight: FinancialInsight
    @Binding var feedbackState: FeedbackState
    var onAction: () -> Void
    
    var body: some View {
        PremiumGlassCard(.inset) {
            HStack(spacing: 16) {
                iconForType(insight.type)
                    .font(.system(size: 24))
                    .foregroundColor(colorForType(insight.type))
                    .frame(width: 50, height: 50)
                    .background(colorForType(insight.type).opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 6) {
                    // Title row with confidence badge
                    HStack(spacing: 8) {
                        Text(insight.title)
                            .font(TrimDesignSystem.Typography.subheader)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        ConfidenceBadge(level: insight.confidence, score: insight.confidenceScore)
                    }
                    
                    Text(insight.description)
                        .font(TrimDesignSystem.Typography.body)
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading) {
                            Text("$\(String(format: "%.2f", insight.monthlyImpact))/mo")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            Text("Monthly")
                                .font(.system(size: 8))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        VStack(alignment: .leading) {
                            Text("$\(String(format: "%.2f", insight.annualImpact))/yr")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
                            Text("Potential Saving")
                                .font(.system(size: 8))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .padding(.top, 4)
                    
                    Button(action: onAction) {
                        Text(insight.primaryAction.label)
                            .font(TrimDesignSystem.Typography.body)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(colorForType(insight.type))
                            .foregroundColor(TrimDesignSystem.Colors.background)
                            .cornerRadius(TrimDesignSystem.Radius.small)
                    }
                    .padding(.top, 8)
                    
                    // Feedback row
                    InlineFeedbackRow(
                        insight: insight,
                        feedbackState: $feedbackState
                    )
                }
            }
        }
    }
    
    private func iconForType(_ type: InsightType) -> Image {
        switch type {
        case .subscriptionIncrease, .priceIncrease:
            return Image(systemName: "arrow.up.circle.fill")
        case .duplicateCharge:
            return Image(systemName: "exclamationmark.triangle.fill")
        case .unusualSpending:
            return Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
        case .savingOpportunity:
            return Image(systemName: "lightbulb.fill")
        case .hiddenSubscription:
            return Image(systemName: "eye.slash.circle.fill")
        case .incomeVolatility:
            return Image(systemName: "waveform.path.ecg")
        case .expenseCluster:
            return Image(systemName: "square.stack.3d.up.fill")
        case .opportunityInsight:
            return Image(systemName: "sparkles")
        }
    }
    
    private func colorForType(_ type: InsightType) -> Color {
        switch type {
        case .subscriptionIncrease, .priceIncrease:
            return TrimDesignSystem.Colors.warning
        case .duplicateCharge:
            return TrimDesignSystem.Colors.error
        case .unusualSpending:
            return TrimDesignSystem.Colors.accentSecondary
        case .savingOpportunity, .opportunityInsight:
            return TrimDesignSystem.Colors.accentPrimary
        case .hiddenSubscription:
            return TrimDesignSystem.Colors.warning.opacity(0.8)
        case .incomeVolatility:
            return TrimDesignSystem.Colors.error.opacity(0.8)
        case .expenseCluster:
            return TrimDesignSystem.Colors.accentSecondary.opacity(0.8)
        }
    }
}

// MARK: - Confidence Badge

/// Compact badge showing confidence level with optional numeric score.
struct ConfidenceBadge: View {
    let level: ConfidenceLevel
    let score: Int?
    
    private var color: Color {
        switch level {
        case .high: return TrimDesignSystem.Colors.accentPrimary
        case .medium: return TrimDesignSystem.Colors.warning
        case .low: return TrimDesignSystem.Colors.error
        }
    }
    
    private var label: String {
        if let score = score {
            return "\(score)%"
        }
        return level.rawValue.capitalized
    }
    
    var body: some View {
        Text(label)
            .font(TrimDesignSystem.Typography.caption)
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(color.opacity(0.12))
            )
    }
}
