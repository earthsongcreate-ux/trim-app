import Foundation

// MARK: - Supported Currency

/// ISO 4217 currency codes supported by Trim.
/// Each case carries display metadata for UI rendering.
enum SupportedCurrency: String, Codable, CaseIterable, Identifiable {
    case USD, EUR, GBP, JPY, AUD, CAD, CHF, CNY, INR, MXN
    case BRL, KRW, SGD, HKD, NOK, SEK, DKK, NZD, ZAR, TRY
    case PLN, THB, IDR, PHP, CZK, ILS, CLP, AED, SAR, NGN
    case EGP, KES
    
    var id: String { rawValue }
    
    var symbol: String {
        switch self {
        case .USD: return "$"
        case .EUR: return "€"
        case .GBP: return "£"
        case .JPY: return "¥"
        case .AUD: return "A$"
        case .CAD: return "C$"
        case .CHF: return "CHF"
        case .CNY: return "¥"
        case .INR: return "₹"
        case .MXN: return "MX$"
        case .BRL: return "R$"
        case .KRW: return "₩"
        case .SGD: return "S$"
        case .HKD: return "HK$"
        case .NOK, .SEK, .DKK: return "kr"
        case .NZD: return "NZ$"
        case .ZAR: return "R"
        case .TRY: return "₺"
        case .PLN: return "zł"
        case .THB: return "฿"
        case .IDR: return "Rp"
        case .PHP: return "₱"
        case .CZK: return "Kč"
        case .ILS: return "₪"
        case .CLP: return "CL$"
        case .AED: return "د.إ"
        case .SAR: return "﷼"
        case .NGN: return "₦"
        case .EGP: return "E£"
        case .KES: return "KSh"
        }
    }
    
    var name: String {
        switch self {
        case .USD: return "US Dollar"
        case .EUR: return "Euro"
        case .GBP: return "British Pound"
        case .JPY: return "Japanese Yen"
        case .AUD: return "Australian Dollar"
        case .CAD: return "Canadian Dollar"
        case .CHF: return "Swiss Franc"
        case .CNY: return "Chinese Yuan"
        case .INR: return "Indian Rupee"
        case .MXN: return "Mexican Peso"
        case .BRL: return "Brazilian Real"
        case .KRW: return "South Korean Won"
        case .SGD: return "Singapore Dollar"
        case .HKD: return "Hong Kong Dollar"
        case .NOK: return "Norwegian Krone"
        case .SEK: return "Swedish Krona"
        case .DKK: return "Danish Krone"
        case .NZD: return "New Zealand Dollar"
        case .ZAR: return "South African Rand"
        case .TRY: return "Turkish Lira"
        case .PLN: return "Polish Zloty"
        case .THB: return "Thai Baht"
        case .IDR: return "Indonesian Rupiah"
        case .PHP: return "Philippine Peso"
        case .CZK: return "Czech Koruna"
        case .ILS: return "Israeli Shekel"
        case .CLP: return "Chilean Peso"
        case .AED: return "UAE Dirham"
        case .SAR: return "Saudi Riyal"
        case .NGN: return "Nigerian Naira"
        case .EGP: return "Egyptian Pound"
        case .KES: return "Kenyan Shilling"
        }
    }
    
    var flag: String {
        switch self {
        case .USD: return "🇺🇸"
        case .EUR: return "🇪🇺"
        case .GBP: return "🇬🇧"
        case .JPY: return "🇯🇵"
        case .AUD: return "🇦🇺"
        case .CAD: return "🇨🇦"
        case .CHF: return "🇨🇭"
        case .CNY: return "🇨🇳"
        case .INR: return "🇮🇳"
        case .MXN: return "🇲🇽"
        case .BRL: return "🇧🇷"
        case .KRW: return "🇰🇷"
        case .SGD: return "🇸🇬"
        case .HKD: return "🇭🇰"
        case .NOK: return "🇳🇴"
        case .SEK: return "🇸🇪"
        case .DKK: return "🇩🇰"
        case .NZD: return "🇳🇿"
        case .ZAR: return "🇿🇦"
        case .TRY: return "🇹🇷"
        case .PLN: return "🇵🇱"
        case .THB: return "🇹🇭"
        case .IDR: return "🇮🇩"
        case .PHP: return "🇵🇭"
        case .CZK: return "🇨🇿"
        case .ILS: return "🇮🇱"
        case .CLP: return "🇨🇱"
        case .AED: return "🇦🇪"
        case .SAR: return "🇸🇦"
        case .NGN: return "🇳🇬"
        case .EGP: return "🇪🇬"
        case .KES: return "🇰🇪"
        }
    }
    
    /// Whether this currency uses decimal places (most do, JPY/KRW don't).
    var usesDecimals: Bool {
        switch self {
        case .JPY, .KRW, .CLP: return false
        default: return true
        }
    }
    
    /// Popular currencies shown first in currency picker.
    static var popular: [SupportedCurrency] {
        [.USD, .EUR, .GBP, .JPY, .CAD, .AUD, .CHF, .INR]
    }
}
