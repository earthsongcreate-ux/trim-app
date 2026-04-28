import Foundation

class NegotiationEngine {
    static let shared = NegotiationEngine()
    
    private init() {}
    
    /// Generates a dynamic negotiation script and strategy based on the specific insight.
    func generateNegotiationPlan(for insight: FinancialInsight) -> (strategy: NegotiationStrategy, script: NegotiationScript) {
        let merchant = extractMerchant(from: insight.description)
        
        switch insight.type {
        case .subscriptionIncrease:
            return (.requestRetention, NegotiationScript(
                script: "Hi, I noticed my \(merchant) bill increased recently. I've been a loyal customer, but I'm considering other options. Is there any way to keep my original rate?",
                talkingPoints: [
                    "Mention loyalty as a customer",
                    "Cite the specific price increase amount",
                    "Mention competitor rates if known"
                ],
                expectedOutcome: "A credit or permanent rate reduction."
            ))
            
        case .savingOpportunity:
            return (.downgradePlan, NegotiationScript(
                script: "Hello, I'd like to review my \(merchant) plan. I feel I'm paying for more than I use. Can we explore a more cost-effective tier?",
                talkingPoints: [
                    "Ask about lower-tier plans",
                    "Highlight features you don't use",
                    "Check for unadvertised bundles"
                ],
                expectedOutcome: "Downgrade to a cheaper plan with 30-50% savings."
            ))
            
        case .duplicateCharge:
            return (.contactProvider, NegotiationScript(
                script: "I'm calling about a duplicate charge of $\(String(format: "%.2f", insight.monthlyImpact)) on my statement. I'd like a refund for the second transaction.",
                talkingPoints: [
                    "Provide transaction dates",
                    "Mention this is a billing error",
                    "Request a direct refund to the card"
                ],
                expectedOutcome: "Immediate refund of the duplicate amount."
            ))
            
        default:
            return (.contactProvider, NegotiationScript(
                script: "I'd like to discuss my current \(merchant) billing.",
                talkingPoints: ["Ask for a general discount"],
                expectedOutcome: "General bill reduction."
            ))
        }
    }
    
    private func extractMerchant(from description: String) -> String {
        // Simple extraction for the mock
        let words = description.components(separatedBy: " ")
        return words.first ?? "the provider"
    }
}
