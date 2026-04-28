import SwiftUI

// MARK: - CurrencySelectionView

/// Full-screen currency picker used during onboarding and in settings.
///
/// Features:
/// - Search by currency name, code, or country
/// - Popular currencies section for fast selection
/// - All currencies listed alphabetically
/// - Selected currency highlighted with animation
struct CurrencySelectionView: View {
    @ObservedObject private var currencyService = CurrencyService.shared
    
    @State private var searchText = ""
    @State private var selectedCurrency: SupportedCurrency?
    @State private var hasConfirmed = false
    
    /// Callback fired when the user confirms their currency selection.
    var onCurrencySelected: ((SupportedCurrency) -> Void)?
    
    /// Whether this is being shown during onboarding (shows different UI chrome).
    var isOnboarding: Bool = true
    
    private var filteredCurrencies: [SupportedCurrency] {
        if searchText.isEmpty {
            return SupportedCurrency.allCases.filter { !SupportedCurrency.popular.contains($0) }
        }
        
        let query = searchText.lowercased()
        return SupportedCurrency.allCases.filter { currency in
            currency.rawValue.lowercased().contains(query) ||
            currency.name.lowercased().contains(query) ||
            currency.symbol.lowercased().contains(query)
        }
    }
    
    var body: some View {
        ZStack {
            TrimDesignSystem.Colors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                searchBar
                currencyList
                confirmButton
            }
        }
        .onAppear {
            selectedCurrency = currencyService.baseCurrency
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: TrimDesignSystem.Spacing.s) {
            if isOnboarding {
                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 40))
                    .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
                    .padding(.top, TrimDesignSystem.Spacing.l)
            }
            
            Text(isOnboarding ? "Select Your Currency" : "Base Currency")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(TrimDesignSystem.Colors.textPrimary)
            
            Text("All financial data will be normalized to this currency.")
                .font(.subheadline)
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, TrimDesignSystem.Spacing.l)
        }
        .padding(.bottom, TrimDesignSystem.Spacing.m)
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: TrimDesignSystem.Spacing.s) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
            
            TextField("Search currencies...", text: $searchText)
                .font(.subheadline)
                .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                .autocorrectionDisabled()
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                }
            }
        }
        .padding(TrimDesignSystem.Spacing.s + 2)
        .background(
            RoundedRectangle(cornerRadius: TrimDesignSystem.Radius.medium)
                .fill(TrimDesignSystem.Colors.surface)
        )
        .padding(.horizontal, TrimDesignSystem.Spacing.m)
        .padding(.bottom, TrimDesignSystem.Spacing.s)
    }
    
    // MARK: - Currency List
    
    private var currencyList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                // Popular section
                if searchText.isEmpty {
                    sectionHeader("Popular")
                    
                    ForEach(SupportedCurrency.popular) { currency in
                        currencyRow(currency)
                    }
                    
                    sectionHeader("All Currencies")
                }
                
                ForEach(filteredCurrencies) { currency in
                    currencyRow(currency)
                }
            }
            .padding(.horizontal, TrimDesignSystem.Spacing.m)
        }
    }
    
    // MARK: - Section Header
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(TrimDesignSystem.Colors.textSecondary)
            .padding(.top, TrimDesignSystem.Spacing.m)
            .padding(.bottom, TrimDesignSystem.Spacing.xs)
    }
    
    // MARK: - Currency Row
    
    private func currencyRow(_ currency: SupportedCurrency) -> some View {
        let isSelected = selectedCurrency == currency
        
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedCurrency = currency
            }
        } label: {
            HStack(spacing: TrimDesignSystem.Spacing.s + 4) {
                // Flag
                Text(currency.flag)
                    .font(.system(size: 24))
                
                // Currency info
                VStack(alignment: .leading, spacing: 2) {
                    Text(currency.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                    
                    Text(currency.name)
                        .font(.caption)
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                // Symbol
                Text(currency.symbol)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.vertical, TrimDesignSystem.Spacing.s + 2)
            .padding(.horizontal, TrimDesignSystem.Spacing.s)
            .background(
                RoundedRectangle(cornerRadius: TrimDesignSystem.Radius.small)
                    .fill(isSelected ? TrimDesignSystem.Colors.accentPrimary.opacity(0.1) : Color.clear)
            )
        }
    }
    
    // MARK: - Confirm Button
    
    private var confirmButton: some View {
        VStack(spacing: TrimDesignSystem.Spacing.xs) {
            if let selected = selectedCurrency {
                Text("All amounts will display in \(selected.symbol) (\(selected.rawValue))")
                    .font(.caption)
                    .foregroundColor(TrimDesignSystem.Colors.textSecondary)
            }
            
            Button {
                guard let selected = selectedCurrency else { return }
                currencyService.setBaseCurrency(selected)
                onCurrencySelected?(selected)
            } label: {
                Text("Confirm Currency")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        selectedCurrency != nil
                        ? TrimDesignSystem.Colors.accentPrimary
                        : TrimDesignSystem.Colors.surface
                    )
                    .foregroundColor(selectedCurrency != nil ? .black : TrimDesignSystem.Colors.textSecondary)
                    .cornerRadius(TrimDesignSystem.Radius.medium)
            }
            .disabled(selectedCurrency == nil)
        }
        .padding(TrimDesignSystem.Spacing.m)
        .background(TrimDesignSystem.Colors.background)
    }
}
