/**
 * @module merchantCleaningEngine
 *
 * Merchant Cleaning Engine
 *
 * Transforms raw, noisy bank transaction descriptions into clean,
 * human-readable merchant names.
 *
 * Pipeline stages:
 * 1. Strip payment processor prefixes (PAYPAL *, SQ *, etc.)
 * 2. Remove transaction IDs, hashes, reference numbers
 * 3. Remove URLs and domain fragments
 * 4. Remove trailing location/terminal data
 * 5. Normalize casing and whitespace
 * 6. Extract core merchant identity
 *
 * Design decisions:
 * - Patterns are applied in order — most specific first
 * - Original raw name is NEVER mutated — a new clean string is returned
 * - Returns confidence level based on how much noise was removed
 *
 * Examples:
 *   "AMZN Mktp US*2H3KQ"       → "AMZN Mktp US"
 *   "UBER *TRIP HELP.UBER.COM"  → "Uber Trip"
 *   "SPOTIFY P1234"             → "Spotify"
 *   "PAYPAL *NETFLIX"           → "Netflix"
 *   "SQ *BLUE BOTTLE COFFEE"    → "Blue Bottle Coffee"
 *   "TST* SWEETGREEN #4201"     → "Sweetgreen"
 *   "CHECKCARD 0423 SHELL OIL"  → "Shell Oil"
 */

// MARK: — Payment Processor Prefixes

/**
 * Payment processors, POS terminals, and card network prefixes
 * that appear before the actual merchant name.
 * Ordered by specificity (longer patterns first).
 */
const PROCESSOR_PREFIXES = [
  /^PAYPAL\s*\*\s*/i,
  /^VENMO\s*\*\s*/i,
  /^CASH\s*APP\s*\*\s*/i,
  /^ZELLE\s*\*?\s*/i,
  /^APPLE\.COM\/BILL\s*/i,
  /^GOOGLE\s*\*\s*/i,
  /^AMZN\s*MKTP\s*/i,
  /^AMZN\s*DIGITAL\s*/i,
  /^AMAZON\s*PRIME\s*/i,
  /^SQ\s*\*\s*/i,
  /^SQC\s*\*\s*/i,
  /^TST\s*\*\s*/i,
  /^DOORDASH\s*\*\s*/i,
  /^GRUBHUB\s*\*\s*/i,
  /^DD\s*DOORDASH\s*/i,
  /^UBER\s*\*\s*/i,
  /^UBER\s*EATS\s*\*?\s*/i,
  /^LYFT\s*\*\s*/i,
  /^POS\s+(PURCHASE\s+)?/i,
  /^CHECKCARD\s+(\d{4}\s+)?/i,
  /^DEBIT\s+(CARD\s+)?/i,
  /^ACH\s+(DEBIT\s+|CREDIT\s+)?/i,
  /^RECURRING\s+(PAYMENT\s+)?/i,
  /^AUTOPAY\s*/i,
  /^ONLINE\s+PAYMENT\s*/i,
  /^ELECTRONIC\s+PAYMENT\s*/i,
  /^WIRE\s+TRANSFER\s*/i,
  /^DIRECT\s+DEBIT\s*/i,
  /^PURCHASE\s+AUTHORIZED\s+ON\s+\d{2}\/\d{2}\s*/i,
  /^VISA\s+(DIRECT\s+)?/i,
  /^MASTERCARD\s*/i,
];

// MARK: — Noise Suffixes & Fragments

/**
 * Trailing noise patterns: IDs, hashes, reference numbers,
 * terminal identifiers, and location data.
 */
const NOISE_SUFFIXES = [
  // Transaction IDs and hashes (e.g., *2H3KQ, #1234, ID:5678)
  /\s*\*[A-Z0-9]{3,10}$/i,
  /\s*#\d{2,10}$/,
  /\s*ID:\s*\d+$/i,
  /\s*REF\s*#?\s*\d+$/i,
  /\s*CONF\s*#?\s*[A-Z0-9]+$/i,

  // URLs and domains
  /\s+[A-Z0-9.-]+\.(COM|NET|ORG|IO|CO|APP|DEV)(\/\S*)?$/i,
  /\s+HELP\.[A-Z0-9.-]+\.(COM|NET|ORG)$/i,
  /\s+WWW\.[A-Z0-9.-]+\.(COM|NET|ORG)$/i,

  // Location/terminal suffixes (e.g., "CITY ST", "12345 CA")
  /\s+\d{5}(-\d{4})?\s*$/,
  /\s+[A-Z]{2}\s+\d{5}$/,
  /\s+\d{4,}\s+[A-Z]{2}\s*$/,

  // Card last-4 references (e.g., "x1234", "XXXX1234")
  /\s+[Xx]{2,4}\d{4}$/,

  // Date references in suffixes (e.g., "ON 04/23", "03/15/26")
  /\s+ON\s+\d{2}\/\d{2}(\/\d{2,4})?$/i,
  /\s+\d{2}\/\d{2}(\/\d{2,4})?$/,

  // Terminal/store numbers (e.g., "STORE 4201", "LOC 83")
  /\s+(STORE|LOC|STR|TERMINAL|TRM)\s*#?\s*\d+$/i,

  // Generic trailing alphanumeric codes
  /\s+[A-Z]{1,3}\d{5,}$/,
  /\s+P\d{4,}$/i,

  // Country codes at end
  /\s+[A-Z]{2,3}$/,
];

// MARK: — Internal Fragments

/**
 * Internal noise patterns that appear mid-string.
 */
const INTERNAL_NOISE = [
  // Payment type indicators
  /\s+(DEBIT|CREDIT|PURCHASE|PAYMENT|PMT|PYMT)\s+/gi,

  // Authorization codes
  /\s+AUTH\s*#?\s*\d+/i,

  // Sequence/batch numbers
  /\s+SEQ\s*\d+/i,
  /\s+BATCH\s*\d+/i,
];

// MARK: — Public API

/**
 * Cleans a raw bank transaction name into a human-readable merchant name.
 *
 * @param {string} rawName - The raw transaction description from the bank
 * @returns {{ merchantClean: string, confidence: string }}
 *   - merchantClean: Cleaned, title-cased merchant name
 *   - confidence: "high" | "medium" | "low" based on cleaning certainty
 */
function cleanMerchantName(rawName) {
  if (!rawName || typeof rawName !== "string") {
    return { merchantClean: "Unknown", confidence: "low" };
  }

  const original = rawName.trim();
  let cleaned = original;
  let transformCount = 0;

  // Stage 1: Strip payment processor prefixes
  for (const prefix of PROCESSOR_PREFIXES) {
    if (prefix.test(cleaned)) {
      cleaned = cleaned.replace(prefix, "");
      transformCount++;
      break; // Only strip one prefix (most specific match)
    }
  }

  // Stage 2: Remove noise suffixes
  for (const suffix of NOISE_SUFFIXES) {
    if (suffix.test(cleaned)) {
      cleaned = cleaned.replace(suffix, "");
      transformCount++;
    }
  }

  // Stage 3: Remove internal noise fragments
  for (const pattern of INTERNAL_NOISE) {
    if (pattern.test(cleaned)) {
      cleaned = cleaned.replace(pattern, " ");
      transformCount++;
    }
  }

  // Stage 4: Normalize whitespace
  cleaned = cleaned.replace(/\s{2,}/g, " ").trim();

  // Stage 5: Remove leading/trailing special characters
  cleaned = cleaned.replace(/^[*\-_.,;:]+\s*/, "").replace(/\s*[*\-_.,;:]+$/, "");

  // Stage 6: Title case normalization
  cleaned = toTitleCase(cleaned);

  // Stage 7: Final validation
  if (!cleaned || cleaned.length < 2) {
    return { merchantClean: toTitleCase(original), confidence: "low" };
  }

  // Confidence scoring
  const confidence = scoreConfidence(original, cleaned, transformCount);

  return { merchantClean: cleaned, confidence };
}

/**
 * Converts a string to Title Case with smart handling
 * of common abbreviations and acronyms.
 *
 * @param {string} str
 * @returns {string}
 */
function toTitleCase(str) {
  if (!str) return "";

  // Known acronyms that should stay uppercase
  const acronyms = new Set([
    "ATM", "LLC", "INC", "LTD", "CO", "US", "UK",
    "EU", "BV", "AG", "SA", "AB", "PLC", "GBR",
    "USA", "USD", "AWS", "API",
  ]);

  return str
    .toLowerCase()
    .split(/\s+/)
    .map((word) => {
      const upper = word.toUpperCase();
      if (acronyms.has(upper)) return upper;
      return word.charAt(0).toUpperCase() + word.slice(1);
    })
    .join(" ");
}

/**
 * Scores confidence based on transformation depth.
 *
 * - high:   Minimal changes, name was already fairly clean
 * - medium: Moderate cleaning applied (1-2 transforms)
 * - low:    Heavy cleaning, result may be unreliable
 *
 * @param {string} original
 * @param {string} cleaned
 * @param {number} transformCount
 * @returns {string}
 */
function scoreConfidence(original, cleaned, transformCount) {
  // If nothing changed, original was clean → high
  if (original.trim().toLowerCase() === cleaned.toLowerCase()) {
    return "high";
  }

  // Length ratio: if cleaned is very short relative to original, less confident
  const ratio = cleaned.length / original.length;

  if (transformCount <= 1 && ratio > 0.5) return "high";
  if (transformCount <= 3 && ratio > 0.3) return "medium";
  return "low";
}

module.exports = {
  cleanMerchantName,
  toTitleCase,
};
