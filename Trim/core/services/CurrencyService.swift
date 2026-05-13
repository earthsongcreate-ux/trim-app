import Foundation
import SwiftUI
import Combine

// MARK: - CurrencyService

/// Manages the user's base currency preference and provides
/// formatting utilities for currency display.
///
/// Responsibilities:
/// - Persist/retrieve base currency selection (UserDefaults)
/// - Format amounts with correct symbols and locale rules
/// - Provide dual-currency display data for transactions
///
/// Thread safety: @MainActor ensures UI-safe state updates.
@MainActor
final class CurrencyService: ObservableObject {
    
    static let shared = CurrencyService()
    
    // MARK: - Published State
    
    /// The user's selected base currency.
    @Published private(set) var baseCurrency: SupportedCurrency
    
    /// Whether the base currency has been explicitly set (e.g. during onboarding).
    @Published private(set) var hasSelectedCurrency: Bool
    
    // MARK: - Storage Keys
    
    private enum StorageKey {
        static let baseCurrency = "trim.currency.base"
        static let hasSelected = "trim.currency.hasSelected"
    }
    
    // MARK: - Init
    
    private init() {
        let stored = UserDefaults.standard.string(forKey: StorageKey.baseCurrency)
        if let stored, let currency = SupportedCurrency(rawValue: stored) {
            self.baseCurrency = currency
        } else {
            self.baseCurrency = .USD
        }
        self.hasSelectedCurrency = UserDefaults.standard.bool(forKey: StorageKey.hasSelected)
    }
    
    // MARK: - Public API
    
    /// Sets the user's base currency. Called during onboarding or from settings.
    func setBaseCurrency(_ currency: SupportedCurrency) {
        baseCurrency = currency
        hasSelectedCurrency = true
        UserDefaults.standard.set(currency.rawValue, forKey: StorageKey.baseCurrency)
        UserDefaults.standard.set(true, forKey: StorageKey.hasSelected)
        
        // Notify backend
        Task {
            await syncBaseCurrencyToBackend(currency)
        }
    }
    
    // MARK: - Formatting
    
    /// Formats an amount in the user's base currency.
    ///
    /// Example: `formatBase(64.20)` → "$64.20" (if base is USD)
    func formatBase(_ amount: Double) -> String {
        formatAmount(amount, currency: baseCurrency)
    }
    
    /// Formats an amount in a specific currency.
    ///
    /// Example: `formatAmount(500, currency: .JPY)` → "¥500"
    func formatAmount(_ amount: Double, currency: SupportedCurrency) -> String {
        let absAmount = abs(amount)
        
        if currency.usesDecimals {
            return "\(currency.symbol)\(String(format: "%.2f", absAmount))"
        } else {
            return "\(currency.symbol)\(Int(absAmount))"
        }
    }
    
    /// Formats the original currency amount as secondary display text.
    ///
    /// Returns nil if original == base (no secondary needed).
    ///
    /// Example: `formatOriginal(500, .JPY)` → "(¥500)" or nil if JPY is base
    func formatOriginal(_ amount: Double, currency: SupportedCurrency) -> String? {
        guard currency != baseCurrency else { return nil }
        return "(\(formatAmount(amount, currency: currency)))"
    }
    
    /// Returns a `CurrencyDisplayData` struct for UI rendering.
    func displayData(
        amountConverted: Double,
        amountOriginal: Double,
        currencyOriginal: SupportedCurrency
    ) -> CurrencyDisplayData {
        return CurrencyDisplayData(
            primaryText: formatBase(amountConverted),
            secondaryText: formatOriginal(amountOriginal, currency: currencyOriginal),
            isForeignTransaction: currencyOriginal != baseCurrency
        )
    }
    
    // MARK: - Backend Sync
    
    /// Pushes the base currency preference to the backend.
    private func syncBaseCurrencyToBackend(_ currency: SupportedCurrency) async {
        let baseURL = ProcessInfo.processInfo.environment["TRIM_API_URL"] ?? "http://localhost:8000"
        guard let url = URL(string: "\(baseURL)/api/v1/currency/user/default") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = try? KeychainManager.shared.retrieve(key: "trim_access_token"), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = ["currencyCode": currency.rawValue]
        request.httpBody = try? JSONEncoder().encode(body)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                #if DEBUG
                print("[CurrencyService] Backend sync failed: bad status")
                #endif
                return
            }
            #if DEBUG
            print("[CurrencyService] Base currency synced to backend: \(currency.rawValue)")
            #endif
        } catch {
            #if DEBUG
            print("[CurrencyService] Backend sync failed: \(error.localizedDescription)")
            #endif
        }
    }
}

// MARK: - Currency Display Data

/// Pre-computed display values for rendering a currency amount in the UI.
/// Consumed by `CurrencyAmountView`.
struct CurrencyDisplayData {
    /// Primary text — amount in base currency (e.g., "€64.20")
    let primaryText: String
    
    /// Secondary text — original currency if foreign (e.g., "(¥500)")
    /// Nil when original == base currency.
    let secondaryText: String?
    
    /// Whether this transaction originated in a foreign currency.
    let isForeignTransaction: Bool
}
