import Foundation

enum NetworkError: Error {
    case invalidURL
    case requestFailed
    case decodingError
}

class TrimApiService {
    static let shared = TrimApiService()
    
    /// Backend base URL — injected via environment or defaults to localhost
    private let baseURL: String = {
        ProcessInfo.processInfo.environment["TRIM_API_URL"] ?? "http://localhost:3001"
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
    
    func fetchDashboardData() async throws -> FinancialOverview {
        // Mocking API response
        return FinancialOverview(
            totalMonthlySpend: 2450.00,
            potentialSavings: 142.50,
            healthScore: 82,
            ytdReturn: 0.184
        )
    }
    
    func fetchSubscriptions() async throws -> [Subscription] {
        return [
            Subscription(id: UUID(), name: "Adobe Creative Cloud", amount: 52.99, frequency: "Monthly", category: "Software", lastBilled: Date(), isUnused: true),
            Subscription(id: UUID(), name: "Fitness First", amount: 45.00, frequency: "Monthly", category: "Health", lastBilled: Date(), isUnused: true),
            Subscription(id: UUID(), name: "Hulu", amount: 12.99, frequency: "Monthly", category: "Entertainment", lastBilled: Date(), isUnused: false)
        ]
    }
    
    func fetchTransactions() async throws -> [Transaction] {
        let syncService = TransactionSyncService.shared
        
        // If we have cached transactions, return them immediately
        if !syncService.transactions.isEmpty {
            return syncService.transactions
        }
        
        // Otherwise trigger a refresh from the backend
        await syncService.refreshTransactions()
        return syncService.transactions
    }
    
    func fetchInsights() async throws -> [FinancialInsight] {
        let syncService = TransactionSyncService.shared
        
        // Ensure transactions are loaded
        let _ = try await fetchTransactions()
        
        // Try backend confidence-scored insights first
        if let url = URL(string: "\(baseURL)/api/insights") {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(InsightsResponse.self, from: data)
                if response.success {
                    return response.insights
                }
            } catch {
                // Fall through to local generation
                print("[TrimApiService] Backend insights unavailable: \(error.localizedDescription)")
            }
        }
        
        // Fallback: local insight generation
        if !syncService.insights.isEmpty {
            // Filter by showToUser for locally cached insights
            return syncService.insights.filter { $0.showToUser }
        }
        
        let transactions = syncService.transactions
        var allInsights = FinancialIntelligenceEngine.shared.processTransactions(transactions)
        
        // Freelancer Engine Integration
        let freelancerInsights = FreelancerEngine.shared.generateInsights(from: transactions)
        let mappedFreelancerInsights = freelancerInsights.map { FreelancerEngine.shared.mapToGlobalInsight($0) }
        
        allInsights.append(contentsOf: mappedFreelancerInsights)
        
        // Client-side confidence filter: only show medium+ confidence
        return allInsights.filter { $0.showToUser }
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
