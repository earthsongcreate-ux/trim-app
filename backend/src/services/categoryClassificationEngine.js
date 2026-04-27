/**
 * @module categoryClassificationEngine
 *
 * Category Classification Engine
 *
 * Assigns a financial category to each transaction using a layered approach:
 *
 * Resolution order:
 * 1. Merchant mapping hint (from merchantMappingSystem) — highest priority
 * 2. Keyword-based classification on merchant name
 * 3. Plaid category mapping (from raw bank data)
 * 4. Amount-based heuristics (income detection)
 * 5. Default: "other"
 *
 * Required categories:
 *   subscriptions, transport, food, shopping, income,
 *   utilities, housing, entertainment, software,
 *   insurance, healthcare, other
 *
 * Design decisions:
 * - Each classification includes a confidence score
 * - Original Plaid categories are never discarded — they serve as fallback
 * - Income detection uses amount sign + merchant patterns
 * - Keyword matching is case-insensitive and supports partial matches
 */

// MARK: — Category Constants

/**
 * All valid Trim categories.
 */
const CATEGORIES = {
  SUBSCRIPTIONS: "subscriptions",
  TRANSPORT: "transport",
  FOOD: "food",
  SHOPPING: "shopping",
  INCOME: "income",
  UTILITIES: "utilities",
  HOUSING: "housing",
  ENTERTAINMENT: "entertainment",
  SOFTWARE: "software",
  INSURANCE: "insurance",
  HEALTHCARE: "healthcare",
  OTHER: "other",
};

// MARK: — Keyword Classification Rules

/**
 * Keyword-to-category mapping.
 * Each entry: { keywords: string[], category: string }
 *
 * Keywords are tested against the lowercase merchant name.
 * More specific keywords first to avoid false positives.
 */
const KEYWORD_RULES = [
  // Subscriptions & Software
  {
    keywords: [
      "netflix", "spotify", "hulu", "disney+", "hbo", "peacock",
      "paramount", "apple tv", "youtube premium", "crunchyroll",
      "audible", "kindle unlimited", "amazon prime",
      "adobe", "microsoft 365", "office 365", "github", "slack",
      "zoom", "notion", "figma", "dropbox", "canva", "chatgpt",
      "openai", "linkedin premium", "icloud",
      "planet fitness", "la fitness", "peloton", "equinox",
      "classpass", "gym",
    ],
    category: CATEGORIES.SUBSCRIPTIONS,
  },

  // Transport
  {
    keywords: [
      "uber", "lyft", "taxi", "cab", "rideshare",
      "shell", "chevron", "bp", "exxon", "mobil", "gas",
      "fuel", "petrol", "tesla supercharger", "charging station",
      "parking", "toll", "metro", "transit", "bus",
      "amtrak", "greyhound", "airline", "flight",
    ],
    category: CATEGORIES.TRANSPORT,
  },

  // Food & Dining
  {
    keywords: [
      "starbucks", "mcdonald", "chipotle", "subway", "domino",
      "panera", "chick-fil-a", "burger", "pizza", "taco",
      "sushi", "ramen", "restaurant", "cafe", "coffee",
      "bakery", "diner", "grill", "kitchen",
      "doordash", "grubhub", "uber eats", "instacart", "postmates",
      "whole foods", "trader joe", "kroger", "safeway", "grocery",
      "market", "deli",
    ],
    category: CATEGORIES.FOOD,
  },

  // Shopping
  {
    keywords: [
      "amazon", "walmart", "target", "costco", "best buy",
      "ebay", "etsy", "ikea", "home depot", "lowes",
      "macy", "nordstrom", "zara", "h&m", "gap",
      "nike", "adidas", "apple store", "wayfair",
    ],
    category: CATEGORIES.SHOPPING,
  },

  // Utilities & Telecom
  {
    keywords: [
      "at&t", "att", "verizon", "t-mobile", "tmobile", "sprint",
      "comcast", "xfinity", "spectrum", "charter",
      "con edison", "coned", "pg&e", "pge", "duke energy",
      "water", "electric", "power", "gas bill", "utility",
      "internet", "cable", "broadband", "fiber",
    ],
    category: CATEGORIES.UTILITIES,
  },

  // Housing
  {
    keywords: [
      "rent", "mortgage", "lease", "property",
      "hoa", "condo", "apartment", "housing",
      "landlord", "management",
    ],
    category: CATEGORIES.HOUSING,
  },

  // Entertainment
  {
    keywords: [
      "cinema", "movie", "theater", "theatre", "concert",
      "ticket", "event", "museum", "amusement", "arcade",
      "bowling", "gaming", "steam", "playstation", "xbox",
      "nintendo",
    ],
    category: CATEGORIES.ENTERTAINMENT,
  },

  // Insurance
  {
    keywords: [
      "geico", "state farm", "progressive", "allstate",
      "insurance", "insur", "policy", "premium",
      "liberty mutual", "farmers",
    ],
    category: CATEGORIES.INSURANCE,
  },

  // Healthcare
  {
    keywords: [
      "hospital", "clinic", "doctor", "dentist", "dental",
      "pharmacy", "cvs", "walgreens", "medical",
      "health", "urgent care", "lab", "optom",
    ],
    category: CATEGORIES.HEALTHCARE,
  },

  // Income patterns
  {
    keywords: [
      "payroll", "salary", "direct deposit", "wages",
      "employer", "paycheck", "compensation",
      "dividend", "interest earned", "refund",
    ],
    category: CATEGORIES.INCOME,
  },
];

// MARK: — Plaid Category Mapping

/**
 * Maps Plaid's personal_finance_category to Trim categories.
 * Plaid uses a hierarchical category system — we map the primary.
 */
const PLAID_CATEGORY_MAP = {
  // Plaid primary categories → Trim categories
  "FOOD_AND_DRINK": CATEGORIES.FOOD,
  "TRANSPORTATION": CATEGORIES.TRANSPORT,
  "TRAVEL": CATEGORIES.TRANSPORT,
  "RENT_AND_UTILITIES": CATEGORIES.UTILITIES,
  "ENTERTAINMENT": CATEGORIES.ENTERTAINMENT,
  "GENERAL_MERCHANDISE": CATEGORIES.SHOPPING,
  "GENERAL_SERVICES": CATEGORIES.OTHER,
  "MEDICAL": CATEGORIES.HEALTHCARE,
  "PERSONAL_CARE": CATEGORIES.HEALTHCARE,
  "INCOME": CATEGORIES.INCOME,
  "TRANSFER_IN": CATEGORIES.INCOME,
  "TRANSFER_OUT": CATEGORIES.OTHER,
  "LOAN_PAYMENTS": CATEGORIES.HOUSING,
  "GOVERNMENT_AND_NON_PROFIT": CATEGORIES.OTHER,
  "HOME_IMPROVEMENT": CATEGORIES.HOUSING,
  "BANK_FEES": CATEGORIES.OTHER,

  // Legacy Plaid flat categories
  "Food and Drink": CATEGORIES.FOOD,
  "Travel": CATEGORIES.TRANSPORT,
  "Transportation": CATEGORIES.TRANSPORT,
  "Rent": CATEGORIES.HOUSING,
  "Mortgage": CATEGORIES.HOUSING,
  "Utilities": CATEGORIES.UTILITIES,
  "Entertainment": CATEGORIES.ENTERTAINMENT,
  "Recreation": CATEGORIES.ENTERTAINMENT,
  "Software": CATEGORIES.SOFTWARE,
  "Insurance": CATEGORIES.INSURANCE,
  "Healthcare": CATEGORIES.HEALTHCARE,
  "Medical": CATEGORIES.HEALTHCARE,
  "Shopping": CATEGORIES.SHOPPING,
  "Payment": CATEGORIES.OTHER,
  "Transfer": CATEGORIES.OTHER,
};

// MARK: — Public API

/**
 * Classifies a transaction into a Trim category.
 *
 * @param {object} params
 * @param {string} params.merchantName - Canonical or cleaned merchant name
 * @param {string|null} params.categoryHint - Category hint from merchant mapping
 * @param {Array<string>|null} params.plaidCategories - Raw Plaid category array
 * @param {object|null} params.plaidPersonalFinanceCategory - Plaid v2 category
 * @param {number} params.amount - Transaction amount (positive = income)
 * @param {string|null} params.rawName - Original raw transaction name
 * @returns {{ category: string, confidence: string }}
 */
function classifyTransaction({
  merchantName,
  categoryHint = null,
  plaidCategories = null,
  plaidPersonalFinanceCategory = null,
  amount = 0,
  rawName = null,
}) {
  // Layer 1: Merchant mapping hint (highest priority — already resolved)
  if (categoryHint && isValidCategory(categoryHint)) {
    return { category: categoryHint, confidence: "high" };
  }

  // Layer 2: Keyword matching on merchant name
  const keywordResult = classifyByKeywords(merchantName);
  if (keywordResult) {
    return keywordResult;
  }

  // Also try keyword matching on raw name for additional context
  if (rawName && rawName !== merchantName) {
    const rawKeywordResult = classifyByKeywords(rawName);
    if (rawKeywordResult) {
      return { category: rawKeywordResult.category, confidence: "medium" };
    }
  }

  // Layer 3: Plaid personal_finance_category (v2 — more accurate)
  if (plaidPersonalFinanceCategory?.primary) {
    const plaidMapped = PLAID_CATEGORY_MAP[plaidPersonalFinanceCategory.primary];
    if (plaidMapped) {
      return { category: plaidMapped, confidence: "medium" };
    }
  }

  // Layer 4: Legacy Plaid categories
  if (plaidCategories && plaidCategories.length > 0) {
    for (const cat of plaidCategories) {
      const mapped = PLAID_CATEGORY_MAP[cat];
      if (mapped) {
        return { category: mapped, confidence: "medium" };
      }
    }
  }

  // Layer 5: Income detection by amount sign
  if (amount > 0) {
    return { category: CATEGORIES.INCOME, confidence: "low" };
  }

  // Layer 6: Default
  return { category: CATEGORIES.OTHER, confidence: "low" };
}

/**
 * Matches a merchant name against keyword rules.
 *
 * @param {string} name
 * @returns {{ category: string, confidence: string } | null}
 */
function classifyByKeywords(name) {
  if (!name) return null;

  const lower = name.toLowerCase();

  for (const rule of KEYWORD_RULES) {
    for (const keyword of rule.keywords) {
      if (lower.includes(keyword)) {
        return { category: rule.category, confidence: "high" };
      }
    }
  }

  return null;
}

/**
 * Validates that a category string is a known Trim category.
 *
 * @param {string} category
 * @returns {boolean}
 */
function isValidCategory(category) {
  return Object.values(CATEGORIES).includes(category);
}

/**
 * Returns all valid Trim categories.
 *
 * @returns {string[]}
 */
function getCategories() {
  return Object.values(CATEGORIES);
}

module.exports = {
  classifyTransaction,
  getCategories,
  isValidCategory,
  CATEGORIES,
};
