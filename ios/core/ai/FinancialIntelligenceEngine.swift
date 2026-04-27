import Foundation

class FinancialIntelligenceEngine {
    static let shared = FinancialIntelligenceEngine()
    
    private init() {}
    
    /// Processes raw transactions to generate high-level financial insights.
    func processTransactions(_ transactions: [Transaction]) -> [FinancialInsight] {
        var insights: [FinancialInsight] = []
        
        // 1. Detect Subscription Price Increases
        insights.append(contentsOf: detectSubscriptionHikes(transactions))
        
        // 2. Detect Duplicate Charges
        insights.append(contentsOf: detectDuplicates(transactions))
        
        // 3. Identify Saving Opportunities (Unused services placeholder)
        insights.append(contentsOf: identifySavingOpportunities(transactions))
        
        return insights
    }
    
    private func detectSubscriptionHikes(_ transactions: [Transaction]) -> [FinancialInsight] {
        var insights: [FinancialInsight] = []
        let recurring = transactions.filter { $0.isRecurring }
        
        let grouped = Dictionary(grouping: recurring, by: { $0.merchant })
        
        for (merchant, txs) in grouped {
            let sorted = txs.sorted(by: { $0.date > $1.date })
            if sorted.count >= 2 {
                let latest = sorted[0]
                let previous = sorted[1]
                
                if latest.amount > previous.amount {
                    let increase = latest.amount - previous.amount
                    insights.append(FinancialInsight(
                        id: UUID(),
                        type: .subscriptionIncrease,
                        title: "Bill Increase Alert",
                        description: "\(merchant) just cost you an extra $\(String(format: "%.2f", increase)). Let's lower it.",
                        monthlyImpact: increase,
                        annualImpact: increase * 12,
                        primaryAction: .negotiate,
                        confidence: .high
                    ))
                }
            }
        }
        
        return insights
    }
    
    private func detectDuplicates(_ transactions: [Transaction]) -> [FinancialInsight] {
        var insights: [FinancialInsight] = []
        let recent = transactions.filter { Calendar.current.isDateInToday($0.date) || Calendar.current.isDateInYesterday($0.date) }
        
        let grouped = Dictionary(grouping: recent, by: { "\($0.merchant)-\($0.amount)-\(Calendar.current.startOfDay(for: $0.date))" })
        
        for txs in grouped.values where txs.count > 1 {
            let merchant = txs[0].merchant
            let amount = txs[0].amount
            insights.append(FinancialInsight(
                id: UUID(),
                type: .duplicateCharge,
                title: "Duplicate Found",
                description: "You were charged twice for \(merchant). Tap to review and dispute.",
                monthlyImpact: amount,
                annualImpact: amount,
                primaryAction: .review,
                confidence: .high
            ))
        }
        
        return insights
    }
    
    private func identifySavingOpportunities(_ transactions: [Transaction]) -> [FinancialInsight] {
        return [
            FinancialInsight(
                id: UUID(),
                type: .savingOpportunity,
                title: "Unused Subscription",
                description: "You haven't used Hulu this month. Stop the waste now.",
                monthlyImpact: 12.99,
                annualImpact: 155.88,
                primaryAction: .cancel,
                confidence: .high
            )
        ]
    }
}
