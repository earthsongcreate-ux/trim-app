import SwiftUI

// MARK: - CurrencyAmountView

/// Reusable view that displays a currency amount in the dual-currency format.
///
/// Renders:
/// - **Primary**: Converted amount in user's base currency (large, prominent)
/// - **Secondary**: Original currency amount in small text (if foreign)
///
/// Example output:
/// ```
///   €64.20
///   (¥500)
/// ```
///
/// Usage:
/// ```swift
/// CurrencyAmountView(transaction: transaction)
/// CurrencyAmountView(
///     amountConverted: 64.20,
///     amountOriginal: 500,
///     currencyOriginal: .JPY
/// )
/// ```
struct CurrencyAmountView: View {
    let displayData: CurrencyDisplayData
    
    /// Primary amount font size. Defaults to body.
    var primaryFont: Font = .body
    
    /// Whether to show the amount as positive/negative with color.
    var showSign: Bool = false
    
    /// Alignment for the text stack.
    var alignment: HorizontalAlignment = .trailing
    
    // MARK: - Convenience Inits
    
    /// Initialize from a Transaction model.
    init(transaction: Transaction, primaryFont: Font = .body, showSign: Bool = false, alignment: HorizontalAlignment = .trailing) {
        let service = CurrencyService.shared
        self.displayData = service.displayData(
            amountConverted: transaction.amountConverted,
            amountOriginal: transaction.amountOriginal,
            currencyOriginal: transaction.originalCurrency ?? service.baseCurrency
        )
        self.primaryFont = primaryFont
        self.showSign = showSign
        self.alignment = alignment
    }
    
    /// Initialize from raw currency values.
    init(amountConverted: Double, amountOriginal: Double, currencyOriginal: SupportedCurrency, primaryFont: Font = .body, showSign: Bool = false, alignment: HorizontalAlignment = .trailing) {
        self.displayData = CurrencyService.shared.displayData(
            amountConverted: amountConverted,
            amountOriginal: amountOriginal,
            currencyOriginal: currencyOriginal
        )
        self.primaryFont = primaryFont
        self.showSign = showSign
        self.alignment = alignment
    }
    
    /// Initialize from pre-computed display data.
    init(displayData: CurrencyDisplayData, primaryFont: Font = .body, showSign: Bool = false, alignment: HorizontalAlignment = .trailing) {
        self.displayData = displayData
        self.primaryFont = primaryFont
        self.showSign = showSign
        self.alignment = alignment
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            // Primary — base currency amount
            Text(displayData.primaryText)
                .font(primaryFont)
                .fontWeight(.semibold)
                .foregroundColor(TrimDesignSystem.Colors.textPrimary)
            
            // Secondary — original currency (only for foreign transactions)
            if let secondary = displayData.secondaryText {
                Text(secondary)
                    .font(.system(size: 11))
                    .foregroundColor(TrimDesignSystem.Colors.textSecondary)
            }
        }
    }
}

// MARK: - CurrencyBadge

/// Small inline badge showing the original currency code for foreign transactions.
///
/// Example: `[JPY]` in accent color, placed next to a merchant name.
struct CurrencyBadge: View {
    let currencyCode: String
    let isForeign: Bool
    
    init(transaction: Transaction) {
        self.currencyCode = transaction.currencyOriginal
        self.isForeign = transaction.isForeignTransaction
    }
    
    var body: some View {
        if isForeign {
            Text(currencyCode)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(TrimDesignSystem.Colors.accentSecondary)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(TrimDesignSystem.Colors.accentSecondary.opacity(0.15))
                )
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
struct CurrencyAmountView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            TrimDesignSystem.Colors.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Same currency
                CurrencyAmountView(
                    displayData: CurrencyDisplayData(
                        primaryText: "$142.50",
                        secondaryText: nil,
                        isForeignTransaction: false
                    ),
                    primaryFont: .title2
                )
                
                // Foreign currency
                CurrencyAmountView(
                    displayData: CurrencyDisplayData(
                        primaryText: "€64.20",
                        secondaryText: "(¥500)",
                        isForeignTransaction: true
                    ),
                    primaryFont: .title2
                )
                
                // Large hero amount
                CurrencyAmountView(
                    displayData: CurrencyDisplayData(
                        primaryText: "£1,234.56",
                        secondaryText: "($1,587.32)",
                        isForeignTransaction: true
                    ),
                    primaryFont: .system(size: 48, weight: .bold)
                )
            }
        }
    }
}
#endif
