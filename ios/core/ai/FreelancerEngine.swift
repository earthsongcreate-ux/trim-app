import Foundation

class FreelancerEngine {
    static let shared = FreelancerEngine()
    
    private init() {}
    
    /// Generates structured freelancer insights based on raw transaction data.
    func generateInsights(from transactions: [Transaction]) -> [FreelancerInsight] {
        var insights: [FreelancerInsight] = []
        
        if let volatility = analyzeIncomeVolatility(transactions: transactions) {
            insights.append(volatility)
        }
        
        let clusters = clusterExpenses(transactions: transactions)
        insights.append(contentsOf: clusters)
        
        if let opportunity = detectOpportunities(transactions: transactions) {
            insights.append(opportunity)
        }
        
        return insights
    }
    
    // MARK: - Detection Logic
    
    private func analyzeIncomeVolatility(transactions: [Transaction]) -> FreelancerInsight? {
        // Simplified detection logic for the mock
        let incomeTransactions = transactions.filter { $0.amount > 0 }
        
        // Example check: Multiple inconsistent sources
        let uniqueSources = Set(incomeTransactions.map { $0.merchantName })
        if uniqueSources.count >= 2 {
            return FreelancerInsight(
                type: .incomeVolatility,
                message: "You had \(uniqueSources.count) inconsistent income sources this month. Cash flow is unstable.",
                impact: "High volatility detected",
                confidence: .high,
                action: .review
            )
        }
        return nil
    }
    
    private func clusterExpenses(transactions: [Transaction]) -> [FreelancerInsight] {
        var clusters: [FreelancerInsight] = []
        let expenses = transactions.filter { $0.amount < 0 }
        
        // Mock Clustering for Software/Tools
        let softwareKeywords = ["Adobe", "Github", "AWS", "Figma", "Slack"]
        let softwareExpenses = expenses.filter { softwareKeywords.contains($0.merchantName) }
        
        let totalSoftwareSpend = softwareExpenses.reduce(0) { $0 + abs($1.amount) }
        if totalSoftwareSpend > 50 {
            clusters.append(
                FreelancerInsight(
                    type: .expenseCluster,
                    message: "$\(Int(totalSoftwareSpend)) spent on software tools this month. Commonly categorized as work-related expense.",
                    impact: "Potential category tracking",
                    confidence: .high,
                    action: .track
                )
            )
        }
        
        // Mock Clustering for Transport
        let transportKeywords = ["Uber", "Lyft", "Shell", "Chevron"]
        let transportExpenses = expenses.filter { transportKeywords.contains($0.merchantName) }
        let totalTransportSpend = transportExpenses.reduce(0) { $0 + abs($1.amount) }
        
        if totalTransportSpend > 100 {
            clusters.append(
                FreelancerInsight(
                    type: .expenseCluster,
                    message: "$\(Int(totalTransportSpend)) spent on transport this month. May be relevant for expense tracking if travel was client-related.",
                    impact: "Potential category tracking",
                    confidence: .medium,
                    action: .review
                )
            )
        }
        
        return clusters
    }
    
    private func detectOpportunities(transactions: [Transaction]) -> FreelancerInsight? {
        // Example logic: High transport spending during earning periods
        // This is a simplified proxy for the prompt's example.
        return FreelancerInsight(
            type: .opportunityInsight,
            message: "High transport spending detected during your primary earning periods. Review for potential mileage tracking.",
            impact: "Optimization opportunity",
            confidence: .medium,
            action: .optimize
        )
    }
    
    // MARK: - Integration
    
    /// Maps specific FreelancerInsight struct to the app's global FinancialInsight model for UI integration
    func mapToGlobalInsight(_ insight: FreelancerInsight) -> FinancialInsight {
        let globalType: InsightType
        switch insight.type {
        case .incomeVolatility: globalType = .incomeVolatility
        case .expenseCluster: globalType = .expenseCluster
        case .opportunityInsight: globalType = .opportunityInsight
        }
        
        let globalAction: CoachingAction
        switch insight.action {
        case .review: globalAction = .review
        case .optimize: globalAction = .optimize
        case .track: globalAction = .track
        }
        
        let globalTitle: String
        switch insight.type {
        case .incomeVolatility: globalTitle = "Income Volatility"
        case .expenseCluster: globalTitle = "Work-Related Expenses"
        case .opportunityInsight: globalTitle = "Tax Deduction Opportunity"
        }
        
        // Dummy values for impact numbers since Freelancer insights focus more on patterns than direct dollar amounts initially.
        return FinancialInsight(
            id: UUID(),
            type: globalType,
            title: globalTitle,
            description: insight.message,
            monthlyImpact: 0,
            annualImpact: 0,
            confidence: insight.confidence,
            primaryAction: globalAction
        )
    }
}
