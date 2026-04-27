/**
 * Currency Service
 *
 * Handles exchange rate fetching, caching, and currency conversion.
 *
 * Design decisions:
 * - Exchange rates are fetched from Frankfurter API (free, no key required)
 * - Rates are cached for 1 hour to minimize API calls
 * - Historical rates are locked at transaction time and never recalculated
 * - All conversions flow through a single `convert()` function
 *
 * Supported currencies: All ISO 4217 codes supported by Frankfurter
 * (EUR, USD, GBP, JPY, AUD, CAD, CHF, CNY, etc.)
 */

const FRANKFURTER_BASE_URL = "https://api.frankfurter.app";

// Cache: { "USD-EUR": { rate: 0.92, fetchedAt: Date } }
const rateCache = new Map();
const CACHE_TTL_MS = 60 * 60 * 1000; // 1 hour

// User base currency store (in-memory — replace with DB in production)
// userId → ISO currency code
const userBaseCurrencies = new Map();

/**
 * All supported currencies with display metadata.
 */
const SUPPORTED_CURRENCIES = {
  USD: { symbol: "$", name: "US Dollar", flag: "🇺🇸" },
  EUR: { symbol: "€", name: "Euro", flag: "🇪🇺" },
  GBP: { symbol: "£", name: "British Pound", flag: "🇬🇧" },
  JPY: { symbol: "¥", name: "Japanese Yen", flag: "🇯🇵" },
  AUD: { symbol: "A$", name: "Australian Dollar", flag: "🇦🇺" },
  CAD: { symbol: "C$", name: "Canadian Dollar", flag: "🇨🇦" },
  CHF: { symbol: "CHF", name: "Swiss Franc", flag: "🇨🇭" },
  CNY: { symbol: "¥", name: "Chinese Yuan", flag: "🇨🇳" },
  INR: { symbol: "₹", name: "Indian Rupee", flag: "🇮🇳" },
  MXN: { symbol: "MX$", name: "Mexican Peso", flag: "🇲🇽" },
  BRL: { symbol: "R$", name: "Brazilian Real", flag: "🇧🇷" },
  KRW: { symbol: "₩", name: "South Korean Won", flag: "🇰🇷" },
  SGD: { symbol: "S$", name: "Singapore Dollar", flag: "🇸🇬" },
  HKD: { symbol: "HK$", name: "Hong Kong Dollar", flag: "🇭🇰" },
  NOK: { symbol: "kr", name: "Norwegian Krone", flag: "🇳🇴" },
  SEK: { symbol: "kr", name: "Swedish Krona", flag: "🇸🇪" },
  DKK: { symbol: "kr", name: "Danish Krone", flag: "🇩🇰" },
  NZD: { symbol: "NZ$", name: "New Zealand Dollar", flag: "🇳🇿" },
  ZAR: { symbol: "R", name: "South African Rand", flag: "🇿🇦" },
  TRY: { symbol: "₺", name: "Turkish Lira", flag: "🇹🇷" },
  PLN: { symbol: "zł", name: "Polish Zloty", flag: "🇵🇱" },
  THB: { symbol: "฿", name: "Thai Baht", flag: "🇹🇭" },
  IDR: { symbol: "Rp", name: "Indonesian Rupiah", flag: "🇮🇩" },
  PHP: { symbol: "₱", name: "Philippine Peso", flag: "🇵🇭" },
  CZK: { symbol: "Kč", name: "Czech Koruna", flag: "🇨🇿" },
  ILS: { symbol: "₪", name: "Israeli Shekel", flag: "🇮🇱" },
  CLP: { symbol: "CL$", name: "Chilean Peso", flag: "🇨🇱" },
  AED: { symbol: "د.إ", name: "UAE Dirham", flag: "🇦🇪" },
  SAR: { symbol: "﷼", name: "Saudi Riyal", flag: "🇸🇦" },
  NGN: { symbol: "₦", name: "Nigerian Naira", flag: "🇳🇬" },
  EGP: { symbol: "E£", name: "Egyptian Pound", flag: "🇪🇬" },
  KES: { symbol: "KSh", name: "Kenyan Shilling", flag: "🇰🇪" },
};

/**
 * Fetches the current exchange rate between two currencies.
 * Results are cached for CACHE_TTL_MS.
 *
 * @param {string} from - Source ISO currency code (e.g., "JPY")
 * @param {string} to - Target ISO currency code (e.g., "EUR")
 * @returns {Promise<number>} The exchange rate
 */
async function getExchangeRate(from, to) {
  if (from === to) return 1.0;

  const cacheKey = `${from}-${to}`;
  const cached = rateCache.get(cacheKey);

  if (cached && Date.now() - cached.fetchedAt < CACHE_TTL_MS) {
    return cached.rate;
  }

  try {
    const response = await fetch(
      `${FRANKFURTER_BASE_URL}/latest?from=${from}&to=${to}`
    );

    if (!response.ok) {
      throw new Error(`Rate API returned ${response.status}`);
    }

    const data = await response.json();
    const rate = data.rates[to];

    if (!rate) {
      throw new Error(`No rate found for ${from} → ${to}`);
    }

    // Cache both directions
    rateCache.set(cacheKey, { rate, fetchedAt: Date.now() });
    rateCache.set(`${to}-${from}`, {
      rate: 1 / rate,
      fetchedAt: Date.now(),
    });

    return rate;
  } catch (error) {
    console.error(`[Currency] Rate fetch failed: ${error.message}`);

    // Return stale cache if available
    if (cached) {
      console.warn(`[Currency] Using stale cache for ${cacheKey}`);
      return cached.rate;
    }

    throw error;
  }
}

/**
 * Fetches historical exchange rate for a specific date.
 * Used when locking rates at transaction time.
 *
 * @param {string} from - Source ISO currency code
 * @param {string} to - Target ISO currency code
 * @param {string} date - Date string (YYYY-MM-DD)
 * @returns {Promise<number>} The historical exchange rate
 */
async function getHistoricalRate(from, to, date) {
  if (from === to) return 1.0;

  const cacheKey = `${from}-${to}-${date}`;
  const cached = rateCache.get(cacheKey);

  // Historical rates never change — cache indefinitely
  if (cached) {
    return cached.rate;
  }

  try {
    const response = await fetch(
      `${FRANKFURTER_BASE_URL}/${date}?from=${from}&to=${to}`
    );

    if (!response.ok) {
      // Frankfurter may not have weekend dates — fall back to latest
      console.warn(
        `[Currency] Historical rate unavailable for ${date}, using latest`
      );
      return getExchangeRate(from, to);
    }

    const data = await response.json();
    const rate = data.rates[to];

    if (!rate) {
      throw new Error(`No historical rate for ${from} → ${to} on ${date}`);
    }

    // Cache historical rate permanently (it won't change)
    rateCache.set(cacheKey, { rate, fetchedAt: Date.now() });

    return rate;
  } catch (error) {
    console.error(`[Currency] Historical rate fetch failed: ${error.message}`);
    // Fall back to current rate
    return getExchangeRate(from, to);
  }
}

/**
 * Converts an amount from one currency to another.
 *
 * @param {number} amount - The amount to convert
 * @param {string} from - Source ISO currency code
 * @param {string} to - Target ISO currency code
 * @param {number} [rate] - Optional pre-fetched rate (for locked rates)
 * @returns {Promise<{amount: number, rate: number}>}
 */
async function convert(amount, from, to, rate = null) {
  if (from === to) {
    return { amount, rate: 1.0 };
  }

  const exchangeRate = rate || (await getExchangeRate(from, to));
  const converted = Math.round(amount * exchangeRate * 100) / 100;

  return { amount: converted, rate: exchangeRate };
}

/**
 * Sets the base currency for a user.
 *
 * @param {string} userId - The user identifier
 * @param {string} currencyCode - ISO 4217 currency code
 */
function setUserBaseCurrency(userId, currencyCode) {
  const upper = currencyCode.toUpperCase();
  if (!SUPPORTED_CURRENCIES[upper]) {
    throw new Error(`Unsupported currency: ${currencyCode}`);
  }
  userBaseCurrencies.set(userId, upper);
}

/**
 * Gets the base currency for a user. Defaults to USD.
 *
 * @param {string} userId
 * @returns {string} ISO currency code
 */
function getUserBaseCurrency(userId) {
  return userBaseCurrencies.get(userId) || "USD";
}

/**
 * Returns the list of supported currencies with metadata.
 *
 * @returns {Array<object>}
 */
function getSupportedCurrencies() {
  return Object.entries(SUPPORTED_CURRENCIES).map(([code, meta]) => ({
    code,
    ...meta,
  }));
}

module.exports = {
  getExchangeRate,
  getHistoricalRate,
  convert,
  setUserBaseCurrency,
  getUserBaseCurrency,
  getSupportedCurrencies,
  SUPPORTED_CURRENCIES,
};
