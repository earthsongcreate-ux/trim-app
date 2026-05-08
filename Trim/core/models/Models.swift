import Foundation

struct Subscription: Identifiable, Codable {
    let id: UUID
    let name: String
    let amount: Double
    let frequency: String
    let category: String
    let lastBilled: Date
    let isUnused: Bool
}

struct FinancialOverview: Codable {
    let totalMonthlySpend: Double
    let potentialSavings: Double
    let healthScore: Int // 0-100
    let ytdReturn: Double // For the portfolio performance view
}

enum ConfidenceLevel: String, Codable {
    case high, medium, low
}

enum TransactionCategory: String, Codable {
    case housing, transportation, transport, food, utilities
    case entertainment, software, insurance, healthcare
    case subscriptions, shopping, income, other, miscellaneous
}

struct Transaction: Identifiable, Codable {
    let id: UUID
    let date: Date
    let merchant: String
    let category: TransactionCategory
    let isRecurring: Bool
    let confidence: ConfidenceLevel
    
    // MARK: - Currency Normalization Fields
    
    /// Amount in the original transaction currency.
    let amountOriginal: Double
    
    /// ISO currency code of the original transaction (e.g., "JPY").
    let currencyOriginal: String
    
    /// Amount converted to the user's base currency.
    let amountConverted: Double
    
    /// User's base currency code (e.g., "EUR").
    let currencyBase: String
    
    /// Exchange rate locked at the time of transaction ingest.
    /// Historical conversions are never recalculated.
    let exchangeRateAtTime: Double
    
    /// Legacy accessor — returns the converted (base currency) amount.
    var amount: Double { amountConverted }
    
    /// Alias for FreelancerEngine compatibility.
    var merchantName: String { merchant }
    
    // MARK: - Normalization Enrichment Fields
    
    /// Raw merchant name from the bank (preserved, never mutated).
    let merchantRaw: String?
    
    /// Detected recurring billing interval ("monthly", "annual", etc.)
    let recurringInterval: String?
    
    /// Per-field confidence scores from the normalization pipeline.
    let confidenceScores: ConfidenceScores?
    
    /// Whether this transaction originated in a foreign currency.
    var isForeignTransaction: Bool {
        currencyOriginal != currencyBase
    }
    
    /// Resolved `SupportedCurrency` for the original transaction currency.
    var originalCurrency: SupportedCurrency? {
        SupportedCurrency(rawValue: currencyOriginal)
    }
    
    /// Resolved `SupportedCurrency` for the user's base currency.
    var baseCurrencyEnum: SupportedCurrency? {
        SupportedCurrency(rawValue: currencyBase)
    }
    
    // MARK: - Custom Decoding (Backend JSON)
    
    /// Handles both new (currency-normalized) and legacy backend formats.
    ///
    /// New format includes: amountOriginal, currencyOriginal, amountConverted,
    /// currencyBase, exchangeRateAtTime
    ///
    /// Legacy format: amount, and currency fields default to USD/1.0
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // ID: try UUID first, then parse from string
        if let uuid = try? container.decode(UUID.self, forKey: .id) {
            self.id = uuid
        } else {
            let idString = try container.decode(String.self, forKey: .id)
            self.id = UUID(uuidString: idString) ?? UUID()
        }
        
        // Date: try Date first, then parse from string
        if let date = try? container.decode(Date.self, forKey: .date) {
            self.date = date
        } else {
            let dateString = try container.decode(String.self, forKey: .date)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            self.date = formatter.date(from: dateString) ?? Date()
        }
        
        // Legacy amount (used as fallback)
        let legacyAmount = try container.decode(Double.self, forKey: .amount)
        
        // Currency normalization — with fallback to legacy single-amount format
        self.amountOriginal = (try? container.decode(Double.self, forKey: .amountOriginal)) ?? legacyAmount
        self.currencyOriginal = (try? container.decode(String.self, forKey: .currencyOriginal)) ?? "USD"
        self.amountConverted = (try? container.decode(Double.self, forKey: .amountConverted)) ?? legacyAmount
        self.currencyBase = (try? container.decode(String.self, forKey: .currencyBase)) ?? "USD"
        self.exchangeRateAtTime = (try? container.decode(Double.self, forKey: .exchangeRateAtTime)) ?? 1.0
        
        // Merchant: prefer merchantName, fall back to merchant
        if let name = try? container.decode(String.self, forKey: .merchantName) {
            self.merchant = name
        } else {
            self.merchant = try container.decode(String.self, forKey: .merchant)
        }
        
        // Category: decode from string, default to miscellaneous
        if let cat = try? container.decode(TransactionCategory.self, forKey: .category) {
            self.category = cat
        } else {
            self.category = .miscellaneous
        }
        
        self.isRecurring = (try? container.decode(Bool.self, forKey: .isRecurring)) ?? false
        self.recurringInterval = try? container.decode(String.self, forKey: .recurringInterval)
        self.merchantRaw = try? container.decode(String.self, forKey: .merchantRaw)
        self.confidenceScores = try? container.decode(ConfidenceScores.self, forKey: .confidenceScores)
        
        // Confidence: decode from string, default to medium
        if let conf = try? container.decode(ConfidenceLevel.self, forKey: .confidence) {
            self.confidence = conf
        } else {
            self.confidence = .medium
        }
    }
    
    /// Full memberwise initializer for in-code construction.
    init(
        id: UUID,
        date: Date,
        amountOriginal: Double,
        currencyOriginal: String,
        amountConverted: Double,
        currencyBase: String,
        exchangeRateAtTime: Double,
        merchant: String,
        category: TransactionCategory,
        isRecurring: Bool,
        confidence: ConfidenceLevel,
        merchantRaw: String? = nil,
        recurringInterval: String? = nil,
        confidenceScores: ConfidenceScores? = nil
    ) {
        self.id = id
        self.date = date
        self.amountOriginal = amountOriginal
        self.currencyOriginal = currencyOriginal
        self.amountConverted = amountConverted
        self.currencyBase = currencyBase
        self.exchangeRateAtTime = exchangeRateAtTime
        self.merchant = merchant
        self.category = category
        self.isRecurring = isRecurring
        self.confidence = confidence
        self.merchantRaw = merchantRaw
        self.recurringInterval = recurringInterval
        self.confidenceScores = confidenceScores
    }
    
    /// Legacy convenience initializer — treats amount as same-currency.
    init(id: UUID, date: Date, amount: Double, merchant: String, category: TransactionCategory, isRecurring: Bool, confidence: ConfidenceLevel) {
        self.init(
            id: id,
            date: date,
            amountOriginal: amount,
            currencyOriginal: CurrencyService.shared.baseCurrency.rawValue,
            amountConverted: amount,
            currencyBase: CurrencyService.shared.baseCurrency.rawValue,
            exchangeRateAtTime: 1.0,
            merchant: merchant,
            category: category,
            isRecurring: isRecurring,
            confidence: confidence
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(amountConverted, forKey: .amount)
        try container.encode(merchant, forKey: .merchant)
        try container.encode(merchant, forKey: .merchantName)
        try container.encode(category, forKey: .category)
        try container.encode(isRecurring, forKey: .isRecurring)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(amountOriginal, forKey: .amountOriginal)
        try container.encode(currencyOriginal, forKey: .currencyOriginal)
        try container.encode(amountConverted, forKey: .amountConverted)
        try container.encode(currencyBase, forKey: .currencyBase)
        try container.encode(exchangeRateAtTime, forKey: .exchangeRateAtTime)
        try container.encodeIfPresent(merchantRaw, forKey: .merchantRaw)
        try container.encodeIfPresent(recurringInterval, forKey: .recurringInterval)
        try container.encodeIfPresent(confidenceScores, forKey: .confidenceScores)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, date, amount, merchant, merchantName, category, isRecurring, confidence
        case amountOriginal, currencyOriginal, amountConverted, currencyBase, exchangeRateAtTime
        case merchantRaw, recurringInterval, confidenceScores
    }
}

// MARK: - Confidence Scores

/// Per-field confidence breakdown from the normalization pipeline.
struct ConfidenceScores: Codable {
    let merchant: String?
    let category: String?
    let recurring: String?
}

enum InsightType: String, Codable {
    case duplicateCharge = "duplicate_charge"
    case priceIncrease = "price_increase"
    case subscriptionIncrease = "subscription_increase"
    case hiddenSubscription = "hidden_subscription"
    case savingOpportunity = "saving_opportunity"
    case unusualSpending = "unusual_spending"
    
    // Freelancer Types
    case incomeVolatility = "income_volatility"
    case expenseCluster = "expense_cluster"
    case opportunityInsight = "opportunity_insight"
}

enum CoachingAction: String, Codable {
    case review = "review"
    case cancel = "cancel"
    case negotiate = "negotiate"
    case optimize = "optimize"
    case track = "track"
    case dismiss = "dismiss"
    
    var label: String {
        switch self {
        case .review: return "Review Activity"
        case .cancel: return "Cancel Service"
        case .negotiate: return "Negotiate Bill"
        case .optimize: return "Optimize Spending"
        case .track: return "Track Category"
        case .dismiss: return "Dismiss"
        }
    }
}

struct FinancialInsight: Identifiable, Codable {
    let id: UUID
    let type: InsightType
    let title: String
    let description: String
    let monthlyImpact: Double
    let annualImpact: Double
    let primaryAction: CoachingAction
    let confidence: ConfidenceLevel
    
    // MARK: - Confidence Engine Fields
    
    /// Numeric confidence score from the backend engine (0–100).
    let confidenceScore: Int?
    
    /// Human-readable reasoning explaining the score.
    let reasoning: String?
    
    /// Whether the backend confidence engine approved this for display.
    let showToUser: Bool
    
    /// Merchant associated with this insight (if applicable).
    let merchant: String?
    
    // MARK: - Decoding
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // ID: try UUID first, then parse from string
        if let uuid = try? container.decode(UUID.self, forKey: .id) {
            self.id = uuid
        } else if let idString = try? container.decode(String.self, forKey: .id) {
            self.id = UUID(uuidString: idString) ?? UUID()
        } else {
            self.id = UUID()
        }
        
        self.type = (try? container.decode(InsightType.self, forKey: .type)) ?? .savingOpportunity
        self.title = (try? container.decode(String.self, forKey: .title)) ?? ""
        self.description = (try? container.decode(String.self, forKey: .description)) ?? ""
        self.monthlyImpact = (try? container.decode(Double.self, forKey: .monthlyImpact)) ?? 0
        self.annualImpact = (try? container.decode(Double.self, forKey: .annualImpact)) ?? 0
        self.primaryAction = (try? container.decode(CoachingAction.self, forKey: .primaryAction)) ?? .review
        self.confidence = (try? container.decode(ConfidenceLevel.self, forKey: .confidence)) ?? .medium
        
        // Confidence engine fields (backward compatible — may not exist)
        self.confidenceScore = try? container.decode(Int.self, forKey: .confidenceScore)
        self.reasoning = try? container.decode(String.self, forKey: .reasoning)
        self.showToUser = (try? container.decode(Bool.self, forKey: .showToUser)) ?? true
        self.merchant = try? container.decode(String.self, forKey: .merchant)
    }
    
    // MARK: - Memberwise Init (for in-code construction)
    
    init(
        id: UUID,
        type: InsightType,
        title: String,
        description: String,
        monthlyImpact: Double,
        annualImpact: Double,
        primaryAction: CoachingAction,
        confidence: ConfidenceLevel,
        confidenceScore: Int? = nil,
        reasoning: String? = nil,
        showToUser: Bool = true,
        merchant: String? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.monthlyImpact = monthlyImpact
        self.annualImpact = annualImpact
        self.primaryAction = primaryAction
        self.confidence = confidence
        self.confidenceScore = confidenceScore
        self.reasoning = reasoning
        self.showToUser = showToUser
        self.merchant = merchant
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, type, title, description, monthlyImpact, annualImpact
        case primaryAction, confidence, confidenceScore, reasoning
        case showToUser, merchant
    }
}

enum NotificationPriority: Int, Codable {
    case critical = 0 // Immediate (Duplicates, Hikes)
    case high = 1     // Savings opportunities
    case medium = 2   // Digests
    case low = 3      // Silent/Suppressed
}

struct TrimNotification: Identifiable, Codable {
    let id: UUID
    let title: String
    let body: String
    let impactLabel: String // e.g. "$155/year"
    let priority: NotificationPriority
    let type: InsightType
    let scheduledFor: Date
}

struct NegotiationScript: Codable {
    let script: String
    let talkingPoints: [String]
    let expectedOutcome: String
}

enum NegotiationStrategy: String, Codable {
    case contactProvider = "Contact Provider"
    case downgradePlan = "Downgrade Plan"
    case requestRetention = "Request Retention Offer"
}

struct NegotiationOutcome: Codable {
    let success: Bool
    let savingsAmount: Double
    let feedback: String?
}

enum SavingsCategory: String, Codable {
    case canceledSubscription = "Canceled Subscription"
    case negotiatedReduction = "Negotiated Reduction"
    case duplicateRefund = "Duplicate Refund"
}

struct SavingsRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let title: String
    let amount: Double
    let category: SavingsCategory
}

struct SavingsSummary: Codable {
    let totalAnnual: Double
    let totalMonthly: Double
    let canceledTotal: Double
    let negotiatedTotal: Double
    let duplicatesTotal: Double
    
    var reinforcementMessage: String {
        let annualFormatted = CurrencyService.shared.formatBase(totalAnnual)
        let monthlyFormatted = CurrencyService.shared.formatBase(totalMonthly)
        return "You've saved \(annualFormatted) this year. That's \(monthlyFormatted)/month back in your pocket."
    }
}

// MARK: - Freelancer Engine Models

struct FreelancerInsight: Codable {
    let type: FreelancerInsightType
    let message: String
    let impact: String
    let confidence: ConfidenceLevel
    let action: FreelancerAction
}

enum FreelancerInsightType: String, Codable {
    case incomeVolatility = "income_volatility"
    case expenseCluster = "expense_cluster"
    case opportunityInsight = "opportunity_insight"
}

enum FreelancerAction: String, Codable {
    case review = "review"
    case optimize = "optimize"
    case track = "track"
}

// MARK: - User Feedback Loop Models

/// Feedback submission request to POST /api/feedback.
struct FeedbackRequest: Codable {
    let userId: String
    let targetId: String
    let targetType: String          // "insight" or "transaction"
    let feedbackType: String        // "confirm" or "correct"
    let originalPrediction: FeedbackPrediction
    let userCorrection: FeedbackCorrection?
}

/// The system's original prediction being evaluated.
struct FeedbackPrediction: Codable {
    let merchant: String?
    let category: String?
    let isRecurring: Bool?
}

/// The user's correction (when feedbackType === "correct").
struct FeedbackCorrection: Codable {
    let merchant: String?
    let category: String?
    let isRecurring: Bool?
}

/// Server response from the feedback endpoint.
struct FeedbackResponse: Codable {
    let success: Bool
    let feedback: FeedbackMeta?
    let learning: FeedbackLearning?
}

struct FeedbackMeta: Codable {
    let feedbackId: String?
    let feedbackType: String?
    let timestamp: String?
}

struct FeedbackLearning: Codable {
    let applied: Bool?
    let userOverrideSet: Bool?
    let globalCorrectionTracked: Bool?
    let confidenceAdjusted: Bool?
}

/// Tracks the current feedback state for a single insight in the UI.
enum FeedbackState: Equatable {
    case none
    case confirmed
    case corrected
    case submitting
}

// MARK: - Coaching Models

struct CoachingRecommendation: Codable, Identifiable, Equatable {
    var id: String {
        return "\(type)_\(title)"
    }
    let type: String // "save_money", "stabilize_spending", "improve_habits"
    let title: String
    let description: String
    let impact: String // "high", "medium", "low"
    let confidence: String // "high", "medium"
    let actionData: CoachingRecommendationData?
    
    static func == (lhs: CoachingRecommendation, rhs: CoachingRecommendation) -> Bool {
        return lhs.id == rhs.id
    }
}

struct CoachingRecommendationData: Codable, Equatable {
    let insightId: String?
    let merchant: String?
    let type: String?
}

struct CoachingData: Codable {
    let priorityAction: CoachingRecommendation?
    let secondaryActions: [CoachingRecommendation]
    
    enum CodingKeys: String, CodingKey {
        case priorityAction = "priority_action"
        case secondaryActions = "secondary_actions"
    }
}

struct CoachingResponse: Codable {
    let success: Bool
    let coaching: CoachingData?
}

// MARK: - Savings Impact Models

struct SavingsWin: Codable, Identifiable {
    let id: String
    let type: String // "subscription_cancel", "price_reduction", "duplicate", "behavior"
    let amount: Double
    let currency: String
    let frequency: String // "monthly", "yearly", "one_time"
    let source: String
    let date: String
    let description: String
    let confidence: String
}

struct SavingsImpact: Codable {
    let totalSaved: Double
    let monthlySavings: Double
    let annualProjection: Double
    let recentWins: [SavingsWin]
    
    enum CodingKeys: String, CodingKey {
        case totalSaved = "total_saved"
        case monthlySavings = "monthly_savings"
        case annualProjection = "annual_projection"
        case recentWins = "recent_wins"
    }
}

struct SavingsImpactResponse: Codable {
    let success: Bool
    let totalSaved: Double?
    let monthlySavings: Double?
    let annualProjection: Double?
    let recentWins: [SavingsWin]?
    
    enum CodingKeys: String, CodingKey {
        case success
        case totalSaved = "total_saved"
        case monthlySavings = "monthly_savings"
        case annualProjection = "annual_projection"
        case recentWins = "recent_wins"
    }
}

// MARK: - Paywall Models

enum SubscriptionPlan: String, Codable {
    case monthly
    case annual
}

struct PaywallPricing: Codable {
    let monthly: Double
    let annual: Double
    let trialDays: Int
}

struct FoundingAnnualOfferState: Codable, Equatable {
    let limit: Int
    let claimedCount: Int
    
    var remainingCount: Int {
        max(limit - claimedCount, 0)
    }
    
    var isAvailable: Bool {
        claimedCount < limit
    }
}

struct PaywallContent: Codable {
    let headline: String
    let subtext: String
    let pricing: PaywallPricing
    let primaryCta: String
    let secondaryCta: String?
}

struct PaywallData: Codable {
    let type: String // "soft", "hard"
    let triggerReason: String
    let content: PaywallContent
}

struct PaywallEvaluationResponse: Codable {
    let success: Bool
    let showPaywall: Bool
    let reason: String?
    let paywall: PaywallData?
}
