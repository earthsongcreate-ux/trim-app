import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case requestFailed
    case decodingError
    case unauthorized
    case serverError
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The endpoint URL is invalid."
        case .requestFailed:
            return "The network request failed. Please check your connection."
        case .decodingError:
            return "Failed to parse data from the server."
        case .unauthorized:
            return "Your session has expired. Please log in again."
        case .serverError:
            return "The server encountered an error. Please try again later."
        case .custom(let message):
            return message
        }
    }
}

class TrimApiService {
    static let shared = TrimApiService()
    
    /// Backend base URL — injected via environment or defaults to localhost
    private let baseURL: String = {
        ProcessInfo.processInfo.environment["TRIM_API_URL"] ?? "http://127.0.0.1:8000"
    }()
    
    private init() {}
    
    var isUsingLocalBackend: Bool {
        baseURL.contains("127.0.0.1") || baseURL.contains("localhost")
    }
}

/// Response shape from the /api/insights endpoint.
private struct InsightsResponse: Codable {
    let success: Bool
    let insights: [FinancialInsight]
    let count: Int
    let suppressed: Int?
}

extension TrimApiService {
    
    private func getAuthHeaders() throws -> [String: String] {
        let token = try KeychainManager.shared.retrieve(key: "trim_access_token")
        if token.isEmpty { throw NetworkError.unauthorized }
        return [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
    }
    
    private func verifyResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.requestFailed
        }
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401, 403:
            throw NetworkError.unauthorized
        case 500...599:
            throw NetworkError.serverError
        default:
            throw NetworkError.requestFailed
        }
    }
    
    private func makeISO8601Decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let withoutFractional = ISO8601DateFormatter()
        withoutFractional.formatOptions = [.withInternetDateTime]
        
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = withFractional.date(from: string) {
                return date
            }
            if let date = withoutFractional.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
        }
        return decoder
    }

    func fetchDashboardData() async throws -> FinancialOverview {
        // Replace with real backend call
        return FinancialOverview(
            totalMonthlySpend: 2450.00,
            potentialSavings: 142.50,
            healthScore: 82,
            ytdReturn: 0.184
        )
    }
    
    func fetchUserProfile() async throws -> UserProfile {
        guard let url = URL(string: "\(baseURL)/api/v1/profile/me") else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = try getAuthHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try verifyResponse(response)
        
        do {
            return try makeISO8601Decoder().decode(UserProfile.self, from: data)
        } catch {
            print("[TrimApiService] Failed to decode profile: \(error)")
            throw NetworkError.decodingError
        }
    }
    
    func updateUserProfile(
        firstName: String?,
        monthlyIncome: Int?,
        monthlySavingsGoal: Int?,
        onboardingComplete: Bool?
    ) async throws -> UserProfile {
        guard let url = URL(string: "\(baseURL)/api/v1/profile/me") else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = try getAuthHeaders()
        
        var body: [String: Any] = [:]
        if let firstName { body["firstName"] = firstName }
        if let monthlyIncome { body["monthlyIncome"] = monthlyIncome }
        if let monthlySavingsGoal { body["monthlySavingsGoal"] = monthlySavingsGoal }
        if let onboardingComplete { body["onboardingComplete"] = onboardingComplete }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try verifyResponse(response)
        
        do {
            return try makeISO8601Decoder().decode(UserProfile.self, from: data)
        } catch {
            print("[TrimApiService] Failed to decode updated profile: \(error)")
            throw NetworkError.decodingError
        }
    }
    
    func fetchFoundingAnnualOfferState() async throws -> FoundingAnnualOfferState {
        guard let url = URL(string: "\(baseURL)/api/v1/profile/founding-annual-offer") else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = try getAuthHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try verifyResponse(response)
        
        do {
            return try JSONDecoder().decode(FoundingAnnualOfferState.self, from: data)
        } catch {
            print("[TrimApiService] Failed to decode offer state: \(error)")
            throw NetworkError.decodingError
        }
    }
    
    func startPremiumTrial(
        plan: SubscriptionPlan,
        trialDays: Int,
        annualPriceCents: Int,
        annualCurrency: String
    ) async throws -> UserProfile {
        guard let url = URL(string: "\(baseURL)/api/v1/profile/start-trial") else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = try getAuthHeaders()
        
        let body: [String: Any] = [
            "plan": plan.rawValue,
            "trialDays": trialDays,
            "annualPriceCents": annualPriceCents,
            "annualCurrency": annualCurrency,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try verifyResponse(response)
        
        do {
            return try makeISO8601Decoder().decode(UserProfile.self, from: data)
        } catch {
            print("[TrimApiService] Failed to decode trial profile: \(error)")
            throw NetworkError.decodingError
        }
    }

    func fetchSubscriptions() async throws -> [Subscription] {
        let now = Date()
        let lastBilled = Calendar.current.date(byAdding: .day, value: -6, to: now) ?? now
        return [
            Subscription(id: UUID(), name: "Netflix", amount: 15.49, frequency: "monthly", category: "subscriptions", lastBilled: lastBilled, isUnused: false),
            Subscription(id: UUID(), name: "Hulu", amount: 12.99, frequency: "monthly", category: "subscriptions", lastBilled: lastBilled, isUnused: true),
            Subscription(id: UUID(), name: "Spotify", amount: 10.99, frequency: "monthly", category: "subscriptions", lastBilled: lastBilled, isUnused: false),
        ]
    }
    
    func createPlaidLinkToken() async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/v1/plaid/create-link-token") else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = try getAuthHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try verifyResponse(response)
        
        let result = try JSONDecoder().decode([String: String].self, from: data)
        return result["link_token"] ?? ""
    }
    
    func exchangePlaidPublicToken(_ publicToken: String, institutionName: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/v1/plaid/exchange-token") else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = try getAuthHeaders()
        let body = ["public_token": publicToken, "institution_name": institutionName]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        try verifyResponse(response)
    }
    
    func syncTransactions() async throws {
        guard let url = URL(string: "\(baseURL)/api/v1/plaid/transactions/fetch") else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = try getAuthHeaders()
        
        let (_, response) = try await URLSession.shared.data(for: request)
        try verifyResponse(response)
    }
    
    func fetchTransactions() async throws -> [Transaction] {
        guard let url = URL(string: "\(baseURL)/api/v1/plaid/transactions") else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = try getAuthHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try verifyResponse(response)
        
        struct TransactionsResponse: Codable {
            let status: String
            let transactions: [Transaction]
        }
        
        do {
            let result = try JSONDecoder().decode(TransactionsResponse.self, from: data)
            return result.transactions
        } catch {
            print("[TrimApiService] Failed to decode transactions: \(error)")
            throw NetworkError.decodingError
        }
    }
    
    func fetchInsights() async throws -> [FinancialInsight] {
        guard let url = URL(string: "\(baseURL)/api/v1/intelligence/insights") else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = try getAuthHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try verifyResponse(response)
        
        do {
            let result = try JSONDecoder().decode(InsightsResponse.self, from: data)
            return result.insights
        } catch {
            print("[TrimApiService] Failed to decode insights: \(error)")
            throw NetworkError.decodingError
        }
    }
        

    
    func fetchNotifications() async throws -> [TrimNotification] {
        let insights = try await fetchInsights()
        return NotificationIntelligenceEngine.shared.prioritizeInsights(insights)
    }
    
    func fetchSavingsRecords() async throws -> [SavingsRecord] {
        let now = Date()
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: now)!
        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        
        return [
            SavingsRecord(id: UUID(), date: now, title: "Negotiated Comcast Bill", amount: 25.00, category: .negotiatedReduction),
            SavingsRecord(id: UUID(), date: twoDaysAgo, title: "Canceled Hulu", amount: 12.99, category: .canceledSubscription),
            SavingsRecord(id: UUID(), date: lastWeek, title: "Refunded Duplicate Charge", amount: 14.50, category: .duplicateRefund)
        ]
    }
    
    func fetchSavingsSummary() async throws -> SavingsSummary {
        let records = try await fetchSavingsRecords()
        
        let canceled = records.filter { $0.category == .canceledSubscription }.reduce(0) { $0 + $1.amount * 12 }
        let negotiated = records.filter { $0.category == .negotiatedReduction }.reduce(0) { $0 + $1.amount * 12 }
        let duplicates = records.filter { $0.category == .duplicateRefund }.reduce(0) { $0 + $1.amount }
        
        let totalAnnual = canceled + negotiated + duplicates
        let totalMonthly = totalAnnual / 12
        
        return SavingsSummary(
            totalAnnual: totalAnnual,
            totalMonthly: totalMonthly,
            canceledTotal: canceled,
            negotiatedTotal: negotiated,
            duplicatesTotal: duplicates
        )
    }
    
    func fetchCoaching(userId: String = "default") async throws -> CoachingData? {
        guard let url = URL(string: "\(baseURL)/api/v1/coaching") else {
            throw NetworkError.invalidURL
        }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.allHTTPHeaderFields = try getAuthHeaders()
            let (data, response) = try await URLSession.shared.data(for: request)
            try verifyResponse(response)
            let decoded = try JSONDecoder().decode(CoachingResponse.self, from: data)
            return decoded.coaching
        } catch {
            print("[TrimApiService] Coaching fetch failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchSavingsImpact(userId: String = "default") async throws -> SavingsImpact? {
        guard let url = URL(string: "\(baseURL)/api/v1/savings/impact") else {
            throw NetworkError.invalidURL
        }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.allHTTPHeaderFields = try getAuthHeaders()
            let (data, response) = try await URLSession.shared.data(for: request)
            try verifyResponse(response)
            let decoded = try JSONDecoder().decode(SavingsImpactResponse.self, from: data)
            if decoded.success {
                return SavingsImpact(
                    totalSaved: decoded.totalSaved ?? 0.0,
                    monthlySavings: decoded.monthlySavings ?? 0.0,
                    annualProjection: decoded.annualProjection ?? 0.0,
                    recentWins: decoded.recentWins ?? []
                )
            }
            return nil
        } catch {
            print("[TrimApiService] Savings impact fetch failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Paywall Service
    
    func evaluatePaywall(context: String) async throws -> PaywallEvaluationResponse? {
        guard var components = URLComponents(string: "\(baseURL)/api/v1/paywall/evaluate") else {
            throw NetworkError.invalidURL
        }
        
        components.queryItems = [
            URLQueryItem(name: "context", value: context)
        ]
        
        guard let url = components.url else { throw NetworkError.invalidURL }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.allHTTPHeaderFields = try getAuthHeaders()
            let (data, response) = try await URLSession.shared.data(for: request)
            try verifyResponse(response)
            return try JSONDecoder().decode(PaywallEvaluationResponse.self, from: data)
        } catch {
            print("[TrimApiService] Paywall evaluation failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    func interactWithPaywall(action: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/v1/paywall/interact") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = try getAuthHeaders()
        
        let body = ["action": action]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            try verifyResponse(response)
        } catch {
            print("[TrimApiService] Paywall interact failed: \(error.localizedDescription)")
        }
    }
}
