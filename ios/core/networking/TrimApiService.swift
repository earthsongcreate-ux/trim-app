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
        ProcessInfo.processInfo.environment["TRIM_API_URL"] ?? "http://localhost:8000"
    }()
    
    private init() {}
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
        if token.isEmpty { throw NetworkError.requestFailed }
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

    func fetchDashboardData() async throws -> FinancialOverview {
        // Replace with real backend call
        return FinancialOverview(
            totalMonthlySpend: 2450.00,
            potentialSavings: 142.50,
            healthScore: 82,
            ytdReturn: 0.184
        )
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
        guard let url = URL(string: "\(baseURL)/api/coaching?userId=\(userId)") else {
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(CoachingResponse.self, from: data)
            return response.coaching
        } catch {
            print("[TrimApiService] Coaching fetch failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchSavingsImpact(userId: String = "default") async throws -> SavingsImpact? {
        guard let url = URL(string: "\(baseURL)/api/savings/impact?userId=\(userId)") else {
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(SavingsImpactResponse.self, from: data)
            if response.success {
                return SavingsImpact(
                    totalSaved: response.totalSaved ?? 0.0,
                    monthlySavings: response.monthlySavings ?? 0.0,
                    annualProjection: response.annualProjection ?? 0.0,
                    recentWins: response.recentWins ?? []
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
        guard let url = URL(string: "\(baseURL)/api/paywall/evaluate?userId=default&context=\(context)") else {
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return try JSONDecoder().decode(PaywallEvaluationResponse.self, from: data)
        } catch {
            print("[TrimApiService] Paywall evaluation failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    func interactWithPaywall(action: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/paywall/interact") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["userId": "default", "action": action]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let _ = try await URLSession.shared.data(for: request)
        } catch {
            print("[TrimApiService] Paywall interact failed: \(error.localizedDescription)")
        }
    }
}
