/**
 * @module merchantMappingSystem
 *
 * Merchant Mapping System
 *
 * Maps cleaned transaction names to canonical, human-friendly merchant
 * identities using a curated dictionary and fuzzy matching.
 *
 * Architecture:
 * 1. Exact match against canonical dictionary (fastest path)
 * 2. Alias match — checks known aliases/variants
 * 3. Fuzzy match — Levenshtein-based partial string match
 *
 * Design decisions:
 * - Dictionary covers the most common merchants in consumer banking
 * - Fuzzy matching threshold is tuned conservatively (0.75) to avoid
 *   false positives on financial data
 * - Each mapping returns a confidence score
 * - Unknown merchants pass through with "low" confidence
 *
 * Category hints: The dictionary also carries a category hint to
 * accelerate downstream classification.
 */

// MARK: — Canonical Merchant Dictionary

/**
 * Maps canonical merchant name to known aliases and category hint.
 *
 * Structure: { canonical: { aliases: [...], category: string } }
 *
 * Aliases are lowercase — all matching is performed case-insensitively.
 */
const MERCHANT_DICTIONARY = {
  // Streaming & Entertainment
  Netflix: { aliases: ["netflix", "nflx", "netflix.com"], category: "subscriptions" },
  Spotify: { aliases: ["spotify", "spotify ltd", "spotify ab", "spotify usa"], category: "subscriptions" },
  "Disney+": { aliases: ["disney+", "disney plus", "disneyplus", "disney+hotstar"], category: "subscriptions" },
  Hulu: { aliases: ["hulu", "hulu llc", "hulu.com"], category: "subscriptions" },
  "HBO Max": { aliases: ["hbo max", "hbo", "hbomax", "max.com"], category: "subscriptions" },
  "YouTube Premium": { aliases: ["youtube premium", "youtube music", "google youtube", "youtube.com"], category: "subscriptions" },
  "Apple TV+": { aliases: ["apple tv", "apple tv+", "apple.com/bill itunes", "itunes.com"], category: "subscriptions" },
  "Amazon Prime": { aliases: ["amazon prime", "amzn prime", "prime video"], category: "subscriptions" },
  Peacock: { aliases: ["peacock", "peacock tv", "peacocktv"], category: "subscriptions" },
  Paramount: { aliases: ["paramount+", "paramount plus", "paramountplus"], category: "subscriptions" },

  // Shopping
  Amazon: { aliases: ["amazon", "amzn", "amzn mktp", "amazon.com", "amzn digital", "amzn marketplace"], category: "shopping" },
  Walmart: { aliases: ["walmart", "wal-mart", "wm supercenter", "walmart.com"], category: "shopping" },
  Target: { aliases: ["target", "target.com", "tgt"], category: "shopping" },
  Costco: { aliases: ["costco", "costco wholesale", "costco whse"], category: "shopping" },
  "Best Buy": { aliases: ["best buy", "bestbuy", "bestbuy.com"], category: "shopping" },
  eBay: { aliases: ["ebay", "ebay.com", "ebay inc"], category: "shopping" },
  Etsy: { aliases: ["etsy", "etsy.com", "etsy inc"], category: "shopping" },
  Ikea: { aliases: ["ikea", "ikea.com", "ikea us"], category: "shopping" },
  "Home Depot": { aliases: ["home depot", "the home depot", "homedepot"], category: "shopping" },
  Lowes: { aliases: ["lowes", "lowe's", "lowes.com"], category: "shopping" },

  // Transport
  Uber: { aliases: ["uber", "uber bv", "uber trip", "uber eats", "uber technologies"], category: "transport" },
  Lyft: { aliases: ["lyft", "lyft ride", "lyft inc"], category: "transport" },
  Shell: { aliases: ["shell", "shell oil", "shell service"], category: "transport" },
  Chevron: { aliases: ["chevron", "chevron usa"], category: "transport" },
  "BP Gas": { aliases: ["bp", "bp gas", "bp amoco"], category: "transport" },
  ExxonMobil: { aliases: ["exxon", "exxonmobil", "mobil"], category: "transport" },
  Tesla: { aliases: ["tesla", "tesla supercharger", "tesla.com"], category: "transport" },

  // Food & Dining
  Starbucks: { aliases: ["starbucks", "starbucks coffee", "sbux"], category: "food" },
  "McDonald's": { aliases: ["mcdonalds", "mcdonald's", "mcd", "mcdonald"], category: "food" },
  "Chick-fil-A": { aliases: ["chick-fil-a", "chickfila", "chick fil a"], category: "food" },
  Chipotle: { aliases: ["chipotle", "chipotle mexican", "chipotle online"], category: "food" },
  Subway: { aliases: ["subway", "subway restaurant"], category: "food" },
  "Domino's": { aliases: ["dominos", "domino's", "dominos pizza", "domino's pizza"], category: "food" },
  "Panera Bread": { aliases: ["panera", "panera bread", "panera cafe"], category: "food" },
  DoorDash: { aliases: ["doordash", "dd doordash", "doordash inc"], category: "food" },
  Grubhub: { aliases: ["grubhub", "grubhub inc", "seamless"], category: "food" },
  "Uber Eats": { aliases: ["uber eats", "ubereats"], category: "food" },
  Instacart: { aliases: ["instacart", "instacart.com"], category: "food" },
  "Whole Foods": { aliases: ["whole foods", "whole foods market", "wholefoods"], category: "food" },
  "Trader Joe's": { aliases: ["trader joes", "trader joe's", "trader joe"], category: "food" },
  Kroger: { aliases: ["kroger", "kroger fuel", "kroger pharmacy"], category: "food" },
  Safeway: { aliases: ["safeway", "safeway inc"], category: "food" },

  // Software & Subscriptions
  Adobe: { aliases: ["adobe", "adobe systems", "adobe creative", "adobe inc"], category: "subscriptions" },
  Microsoft: { aliases: ["microsoft", "msft", "microsoft 365", "ms office", "microsoft.com"], category: "subscriptions" },
  GitHub: { aliases: ["github", "github inc", "github.com"], category: "subscriptions" },
  Slack: { aliases: ["slack", "slack technologies"], category: "subscriptions" },
  Zoom: { aliases: ["zoom", "zoom.us", "zoom video"], category: "subscriptions" },
  Notion: { aliases: ["notion", "notion labs", "notion.so"], category: "subscriptions" },
  Figma: { aliases: ["figma", "figma inc", "figma.com"], category: "subscriptions" },
  Dropbox: { aliases: ["dropbox", "dropbox inc", "dropbox.com"], category: "subscriptions" },
  AWS: { aliases: ["aws", "amazon web services", "amazonaws"], category: "subscriptions" },
  Google: { aliases: ["google", "google cloud", "google storage", "google one", "google.com"], category: "subscriptions" },
  "Apple iCloud": { aliases: ["icloud", "apple icloud", "apple.com icloud"], category: "subscriptions" },
  Canva: { aliases: ["canva", "canva.com", "canva pty"], category: "subscriptions" },
  ChatGPT: { aliases: ["chatgpt", "openai", "openai.com"], category: "subscriptions" },
  LinkedIn: { aliases: ["linkedin", "linkedin premium", "linkedin.com"], category: "subscriptions" },

  // Fitness & Health
  "Planet Fitness": { aliases: ["planet fitness", "pf planet fitness"], category: "subscriptions" },
  "LA Fitness": { aliases: ["la fitness", "la fitness international"], category: "subscriptions" },
  Peloton: { aliases: ["peloton", "peloton interactive", "onepeloton"], category: "subscriptions" },
  Equinox: { aliases: ["equinox", "equinox fitness"], category: "subscriptions" },
  ClassPass: { aliases: ["classpass", "class pass"], category: "subscriptions" },

  // Utilities
  "AT&T": { aliases: ["at&t", "att", "at&t wireless", "att mobility"], category: "utilities" },
  Verizon: { aliases: ["verizon", "verizon wireless", "vzw"], category: "utilities" },
  "T-Mobile": { aliases: ["t-mobile", "tmobile", "t mobile"], category: "utilities" },
  Comcast: { aliases: ["comcast", "comcast cable", "xfinity"], category: "utilities" },
  Spectrum: { aliases: ["spectrum", "charter spectrum", "charter comm"], category: "utilities" },
  "Con Edison": { aliases: ["con edison", "coned", "consolidated edison"], category: "utilities" },
  PG_E: { aliases: ["pg&e", "pge", "pacific gas"], category: "utilities" },

  // Insurance
  Geico: { aliases: ["geico", "geico insurance", "geico.com"], category: "insurance" },
  "State Farm": { aliases: ["state farm", "statefarm"], category: "insurance" },
  Progressive: { aliases: ["progressive", "progressive insurance"], category: "insurance" },
  Allstate: { aliases: ["allstate", "allstate insurance"], category: "insurance" },

  // Finance
  Venmo: { aliases: ["venmo", "venmo payment", "venmo cashout"], category: "other" },
  PayPal: { aliases: ["paypal", "paypal inc", "paypal payment"], category: "other" },
  "Cash App": { aliases: ["cash app", "cashapp", "square cash"], category: "other" },
  Zelle: { aliases: ["zelle", "zelle payment"], category: "other" },
};

// MARK: — Build Lookup Indices

/**
 * Pre-computed indices for O(1) exact and alias lookups.
 */
const exactLookup = new Map();   // lowercased canonical → canonical
const aliasLookup = new Map();   // lowercased alias → { canonical, category }

for (const [canonical, meta] of Object.entries(MERCHANT_DICTIONARY)) {
  exactLookup.set(canonical.toLowerCase(), { canonical, category: meta.category });

  for (const alias of meta.aliases) {
    aliasLookup.set(alias.toLowerCase(), { canonical, category: meta.category });
  }
}

// MARK: — Fuzzy Matching

/**
 * Computes the Levenshtein distance between two strings.
 *
 * @param {string} a
 * @param {string} b
 * @returns {number} Edit distance
 */
function levenshtein(a, b) {
  const matrix = [];

  for (let i = 0; i <= b.length; i++) {
    matrix[i] = [i];
  }
  for (let j = 0; j <= a.length; j++) {
    matrix[0][j] = j;
  }

  for (let i = 1; i <= b.length; i++) {
    for (let j = 1; j <= a.length; j++) {
      if (b.charAt(i - 1) === a.charAt(j - 1)) {
        matrix[i][j] = matrix[i - 1][j - 1];
      } else {
        matrix[i][j] = Math.min(
          matrix[i - 1][j - 1] + 1, // substitution
          matrix[i][j - 1] + 1,     // insertion
          matrix[i - 1][j] + 1      // deletion
        );
      }
    }
  }

  return matrix[b.length][a.length];
}

/**
 * Calculates similarity ratio (0–1) between two strings.
 *
 * @param {string} a
 * @param {string} b
 * @returns {number} Similarity ratio (1.0 = identical)
 */
function similarity(a, b) {
  if (!a || !b) return 0;
  const maxLen = Math.max(a.length, b.length);
  if (maxLen === 0) return 1;
  return 1 - levenshtein(a, b) / maxLen;
}

/**
 * Checks if needle is a significant substring of haystack.
 * Used for partial match when fuzzy distance is too high.
 *
 * @param {string} haystack
 * @param {string} needle
 * @returns {boolean}
 */
function containsSubstantially(haystack, needle) {
  if (needle.length < 3) return false;
  return haystack.includes(needle);
}

// MARK: — Public API

/**
 * Maps a cleaned merchant name to a canonical identity.
 *
 * Resolution order:
 * 1. Exact canonical match → confidence: "high"
 * 2. Alias match → confidence: "high"
 * 3. Substring/contains match → confidence: "medium"
 * 4. Fuzzy match (similarity ≥ 0.75) → confidence: "medium"
 * 5. No match → pass through original, confidence: "low"
 *
 * @param {string} cleanedName - Output of merchantCleaningEngine
 * @returns {{ merchantCanonical: string, categoryHint: string|null, confidence: string }}
 */
function mapMerchant(cleanedName) {
  if (!cleanedName || typeof cleanedName !== "string") {
    return { merchantCanonical: "Unknown", categoryHint: null, confidence: "low" };
  }

  const normalized = cleanedName.trim().toLowerCase();

  // 1. Exact canonical match
  const exactMatch = exactLookup.get(normalized);
  if (exactMatch) {
    return {
      merchantCanonical: exactMatch.canonical,
      categoryHint: exactMatch.category,
      confidence: "high",
    };
  }

  // 2. Alias match
  const aliasMatch = aliasLookup.get(normalized);
  if (aliasMatch) {
    return {
      merchantCanonical: aliasMatch.canonical,
      categoryHint: aliasMatch.category,
      confidence: "high",
    };
  }

  // 3. Substring match — check if input contains a known alias
  for (const [alias, meta] of aliasLookup.entries()) {
    if (alias.length >= 4 && containsSubstantially(normalized, alias)) {
      return {
        merchantCanonical: meta.canonical,
        categoryHint: meta.category,
        confidence: "medium",
      };
    }
  }

  // 4. Fuzzy match — Levenshtein similarity
  let bestMatch = null;
  let bestScore = 0;

  for (const [alias, meta] of aliasLookup.entries()) {
    // Skip very short aliases for fuzzy (too many false positives)
    if (alias.length < 4) continue;

    const score = similarity(normalized, alias);
    if (score > bestScore && score >= 0.75) {
      bestScore = score;
      bestMatch = { ...meta, score };
    }
  }

  if (bestMatch) {
    return {
      merchantCanonical: bestMatch.canonical,
      categoryHint: bestMatch.category,
      confidence: bestScore >= 0.85 ? "medium" : "low",
    };
  }

  // 5. No match — pass through the cleaned name
  return {
    merchantCanonical: cleanedName,
    categoryHint: null,
    confidence: "low",
  };
}

/**
 * Returns the full merchant dictionary.
 * Useful for admin/debug endpoints.
 *
 * @returns {object}
 */
function getDictionary() {
  return MERCHANT_DICTIONARY;
}

/**
 * Returns the count of known merchants and total aliases.
 *
 * @returns {{ merchants: number, aliases: number }}
 */
function getDictionaryStats() {
  return {
    merchants: Object.keys(MERCHANT_DICTIONARY).length,
    aliases: aliasLookup.size,
  };
}

module.exports = {
  mapMerchant,
  getDictionary,
  getDictionaryStats,
  similarity,
};
