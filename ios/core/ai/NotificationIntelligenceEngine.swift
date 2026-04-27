import Foundation

class NotificationIntelligenceEngine {
    static let shared = NotificationIntelligenceEngine()
    
    private init() {}
    
    /// Converts financial insights into a prioritized notification queue.
    /// Only insights approved by the confidence engine (showToUser = true) are included.
    func prioritizeInsights(_ insights: [FinancialInsight]) -> [TrimNotification] {
        return insights
            .filter { $0.showToUser } // Respect confidence engine filtering
            .compactMap { createNotification(from: $0) }
            .sorted(by: { $0.priority.rawValue < $1.priority.rawValue })
            .filter { $0.priority != .low } // Suppress low-value alerts
    }
    
    private func createNotification(from insight: FinancialInsight) -> TrimNotification? {
        let priority = determinePriority(for: insight)
        let impactLabel = "$\(Int(insight.annualImpact))/yr"
        
        // Ensure message structure: Issue + Impact + Action
        // Keep it under 120 characters
        let body = generateShortBody(for: insight, impact: impactLabel)
        
        return TrimNotification(
            id: UUID(),
            title: insight.title,
            body: body,
            impactLabel: impactLabel,
            priority: priority,
            type: insight.type,
            scheduledFor: determineTiming(for: priority)
        )
    }
    
    private func determinePriority(for insight: FinancialInsight) -> NotificationPriority {
        // Use confidence score to demote uncertain insights
        let score = insight.confidenceScore ?? 60
        
        switch insight.type {
        case .duplicateCharge:
            return score >= 70 ? .critical : .high
        case .subscriptionIncrease, .priceIncrease:
            return score >= 70 ? .critical : .high
        case .hiddenSubscription:
            return score >= 60 ? .high : .medium
        case .savingOpportunity:
            return insight.annualImpact > 100 ? .high : .medium
        case .unusualSpending:
            return score >= 70 ? .high : .medium
        case .incomeVolatility:
            return .medium
        case .expenseCluster:
            return .medium
        case .opportunityInsight:
            return insight.annualImpact > 100 ? .high : .medium
        }
    }
    
    private func determineTiming(for priority: NotificationPriority) -> Date {
        switch priority {
        case .critical:
            return Date() // Immediate
        case .high, .medium:
            // Delay to 9 AM local time tomorrow or next digest slot
            return Calendar.current.nextDate(after: Date(), matching: DateComponents(hour: 9), matchingPolicy: .nextTime)!
        case .low:
            return Date.distantFuture
        }
    }
    
    private func generateShortBody(for insight: FinancialInsight, impact: String) -> String {
        let action = insight.primaryAction.label
        let baseMsg = insight.description
        
        let fullMsg = "\(baseMsg) Impact: \(impact). \(action) now."
        
        if fullMsg.count <= 120 {
            return fullMsg
        } else {
            // Fallback to even shorter version
            return "\(insight.title): \(impact) impact. \(action)."
        }
    }
}
