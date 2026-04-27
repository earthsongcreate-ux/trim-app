import Foundation

// MARK: - TransactionSyncService

/// Fetches synced transactions from the Trim backend and feeds them
/// into the local intelligence engines for analysis.
///
/// This service bridges the backend transaction pipeline with the
/// on-device AI engines:
/// - `FinancialIntelligenceEngine` — duplicate detection, price hikes, savings
/// - `FreelancerEngine` — income volatility, expense clusters, opportunities
///
/// Sync triggers:
/// 1. On app launch (if a connection exists)
/// 2. On new bank connection (after Plaid Link success)
/// 3. On manual pull-to-refresh
///
/// The service does NOT call Plaid directly — it fetches pre-synced,
/// normalized transactions from the Trim backend.
final class TransactionSyncService: ObservableObject {
    
    static let shared = TransactionSyncService()
    
    // MARK: - Published State
    
    /// Current sync state for UI feedback.
    @Published private(set) var syncState: SyncState = .idle
    
    /// All fetched transactions, sorted by date descending.
    @Published private(set) var transactions: [Transaction] = []
    
    /// Latest insights generated from synced transactions.
    @Published private(set) var insights: [FinancialInsight] = []
    
    /// Timestamp of the last successful sync.
    @Published private(set) var lastSyncedAt: Date?
    
    // MARK: - State
    
    enum SyncState: Equatable {
        case idle
        case syncing
        case completed(Int) // transaction count
        case error(String)
        
        var isError: Bool {
            if case .error = self { return true }
            return false
        }
    }
    
    // MARK: - Backend Config
    
    private static let backendBaseURL = "http://localhost:3001/api"
    
    private init() {}
    
    // MARK: - Public API
    
    /// Triggers a backend sync for a specific connection, then fetches
    /// the updated transactions.
    ///
    /// Call this after a new Plaid Link connection is established.
    ///
    /// - Parameter connectionId: The backend connection ID
    @MainActor
    func syncConnection(_ connectionId: String) async {
        syncState = .syncing
        
        do {
            // 1. Trigger backend sync
            try await triggerBackendSync(connectionId: connectionId)
            
            // 2. Fetch updated transactions
            try await fetchTransactions()
            
            // 3. Process through intelligence engines
            processInsights()
            
            lastSyncedAt = Date()
            syncState = .completed(transactions.count)
        } catch {
            syncState = .error("Sync failed. Pull to retry.")
        }
    }
    
    /// Fetches all transactions from the backend without triggering a new sync.
    ///
    /// Use this for app launch and pull-to-refresh when
    /// the backend handles sync scheduling independently.
    @MainActor
    func refreshTransactions() async {
        syncState = .syncing
        
        do {
            try await fetchTransactions()
            processInsights()
            
            lastSyncedAt = Date()
            syncState = .completed(transactions.count)
        } catch {
            syncState = .error("Unable to load transactions.")
        }
    }
    
    /// Triggers a full sync of all connections via the backend.
    ///
    /// Used for manual "sync everything" actions.
    @MainActor
    func syncAllConnections() async {
        syncState = .syncing
        
        do {
            try await triggerBatchSync()
            try await fetchTransactions()
            processInsights()
            
            lastSyncedAt = Date()
            syncState = .completed(transactions.count)
        } catch {
            syncState = .error("Batch sync failed.")
        }
    }
    
    // MARK: - Intelligence Processing
    
    /// Processes fetched transactions through both intelligence engines
    /// to generate actionable insights.
    private func processInsights() {
        guard !transactions.isEmpty else {
            insights = []
            return
        }
        
        // Financial Intelligence Engine — duplicates, hikes, savings
        var allInsights = FinancialIntelligenceEngine.shared
            .processTransactions(transactions)
        
        // Freelancer Engine — income volatility, expense clusters
        let freelancerInsights = FreelancerEngine.shared
            .generateInsights(from: transactions)
        let mapped = freelancerInsights.map {
            FreelancerEngine.shared.mapToGlobalInsight($0)
        }
        
        allInsights.append(contentsOf: mapped)
        
        insights = allInsights
    }
    
    // MARK: - Network
    
    /// Tells the backend to sync transactions for a specific connection.
    private func triggerBackendSync(connectionId: String) async throws {
        guard let url = URL(string: "\(Self.backendBaseURL)/transactions/sync/\(connectionId)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode(SyncResponse.self, from: data)
        guard decoded.success else {
            throw URLError(.badServerResponse)
        }
        
        #if DEBUG
        if let sync = decoded.sync {
            print("[TransactionSync] Added: \(sync.addedCount), Modified: \(sync.modifiedCount), Removed: \(sync.removedCount)")
        }
        #endif
    }
    
    /// Tells the backend to sync all connections.
    private func triggerBatchSync() async throws {
        guard let url = URL(string: "\(Self.backendBaseURL)/transactions/sync-all") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }
    
    /// Fetches all transactions from the backend.
    private func fetchTransactions() async throws {
        guard let url = URL(string: "\(Self.backendBaseURL)/transactions") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode(TransactionsResponse.self, from: data)
        guard decoded.success else {
            throw URLError(.badServerResponse)
        }
        
        transactions = decoded.transactions
    }
}

// MARK: - Response Models

private struct SyncResponse: Decodable {
    let success: Bool
    let sync: SyncSummary?
}

private struct SyncSummary: Decodable {
    let connectionId: String?
    let addedCount: Int
    let modifiedCount: Int
    let removedCount: Int
    let totalStored: Int?
}

private struct TransactionsResponse: Decodable {
    let success: Bool
    let transactions: [Transaction]
    let count: Int
}
