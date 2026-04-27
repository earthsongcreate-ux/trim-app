/**
 * @module transactionNormalizationService
 *
 * Transaction Normalization Service — Orchestrator
 *
 * Coordinates the full normalization pipeline:
 *   Raw Bank Data → Clean → Map → Classify → Detect Recurring → Enriched Output
 *
 * This service is the single entry point for transaction enrichment.
 * Downstream consumers (FinancialIntelligenceEngine, FreelancerEngine,
 * InsightsView, SavingsDashboard) receive fully normalized data.
 *
 * Pipeline stages:
 * 1. Merchant Cleaning — strip noise from raw names
 * 2. Merchant Mapping  — resolve canonical merchant identity
 * 3. Category Classification — assign financial category
 * 4. Recurring Detection — flag subscription patterns
 *
 * Behavior rules:
 * - Raw transaction data is NEVER overwritten
 * - Original values are always preserved alongside enriched data
 * - All inferred data includes confidence scores
 * - Prefer clarity over perfection
 *
 * Output format (per transaction):
 * {
 *   id, date,
 *   amount_original, currency_original,
 *   amount_converted, currency_base,
 *   merchant_raw, merchant_clean, merchant_canonical,
 *   category,
 *   confidence_scores: { merchant, category, recurring },
 *   is_recurring, recurring_interval,
 *   exchange_rate_at_time
 * }
 */

const { cleanMerchantName } = require("./merchantCleaningEngine");
const { mapMerchant } = require("./merchantMappingSystem");
const { classifyTransaction } = require("./categoryClassificationEngine");
const { analyzeRecurring, checkTransaction } = require("./recurringDetectionEngine");
const { getUserOverride } = require("./feedbackStore");

// In-memory recurring analysis cache — rebuilt on each full sync
let recurringCache = new Map();

// MARK: — Single Transaction Normalization

/**
 * Normalizes a single raw Plaid transaction through the full pipeline.
 *
 * @param {object} rawTx - Raw transaction from Plaid API
 * @param {object} [options]
 * @param {string} [options.connectionId] - Parent connection ID
 * @param {string} [options.baseCurrency] - User's base currency code
 * @returns {object} Fully normalized transaction
 */
function normalizeTransaction(rawTx, options = {}) {
  const { connectionId = null, baseCurrency = "USD", userId = null } = options;
  const rawName = rawTx.name || "";
  const rawMerchant = rawTx.merchant_name || null;

  // Stage 1: Clean the merchant name
  const nameToClean = rawMerchant || rawName;
  const { merchantClean, confidence: cleanConfidence } = cleanMerchantName(nameToClean);

  // Stage 2: Map to canonical merchant identity
  const { merchantCanonical, categoryHint, confidence: mapConfidence } = mapMerchant(merchantClean);

  // Stage 3: Classify into category
  const { category, confidence: categoryConfidence } = classifyTransaction({
    merchantName: merchantCanonical,
    categoryHint,
    plaidCategories: rawTx.category || null,
    plaidPersonalFinanceCategory: rawTx.personal_finance_category || null,
    amount: rawTx.amount || 0,
    rawName,
  });

  // Stage 4: Check against recurring cache
  const recurringResult = checkTransaction(
    { merchantName: merchantCanonical, name: rawName },
    recurringCache
  );

  // Determine the best merchant confidence from cleaning + mapping
  const merchantConfidence = resolveConfidence(cleanConfidence, mapConfidence);

  return {
    // Identifiers
    plaidTransactionId: rawTx.transaction_id,
    connectionId,
    accountId: rawTx.account_id,

    // Date
    date: rawTx.date,

    // Raw data — preserved, never mutated
    merchantRaw: rawName,

    // Enriched merchant data
    merchantClean,
    merchantName: merchantCanonical,

    // Currency (populated by transactionStore currency layer)
    amountOriginal: rawTx.amount,
    currencyOriginal: rawTx.iso_currency_code || "USD",
    amountConverted: rawTx.amount, // Placeholder — currency service fills this
    currencyBase: baseCurrency,
    exchangeRateAtTime: 1.0, // Placeholder — currency service fills this

    // Legacy aliases
    amount: rawTx.amount,
    currency: baseCurrency,

    // Classification
    category,

    // Recurring detection
    isRecurring: recurringResult.isRecurring,
    recurringInterval: recurringResult.interval,

    // Confidence scores for all inferred data
    confidenceScores: {
      merchant: merchantConfidence,
      category: categoryConfidence,
      recurring: recurringResult.confidence,
    },

    // Metadata
    pending: rawTx.pending || false,
    createdAt: new Date().toISOString(),
  };

  // Stage 5: Apply user-specific feedback overrides
  if (userId) {
    applyUserOverrides(result, userId);
  }

  return result;
}

// MARK: — Batch Normalization

/**
 * Normalizes a batch of raw transactions.
 * Also rebuilds the recurring detection cache from the full set.
 *
 * @param {Array<object>} rawTransactions - Raw Plaid transactions
 * @param {object} [options]
 * @param {string} [options.connectionId]
 * @param {string} [options.baseCurrency]
 * @param {Array<object>} [options.existingTransactions] - Previously stored transactions for recurring analysis
 * @returns {Array<object>} Normalized transactions
 */
function normalizeBatch(rawTransactions, options = {}) {
  const { existingTransactions = [] } = options;

  // Pre-normalize all transactions (without recurring)
  const normalized = rawTransactions.map((tx) =>
    normalizeTransaction(tx, options)
  );

  // Rebuild recurring cache from all known transactions
  const allForRecurring = [...existingTransactions, ...normalized];
  recurringCache = analyzeRecurring(allForRecurring);

  // Re-apply recurring detection with the updated cache
  for (const tx of normalized) {
    const result = checkTransaction(
      { merchantName: tx.merchantName, name: tx.merchantRaw },
      recurringCache
    );
    tx.isRecurring = result.isRecurring;
    tx.recurringInterval = result.interval;
    tx.confidenceScores.recurring = result.confidence;
  }

  return normalized;
}

// MARK: — Recurring Analysis API

/**
 * Returns the current recurring analysis results.
 * Useful for subscription dashboards and insights.
 *
 * @returns {Array<object>} Recurring merchant analysis
 */
function getRecurringAnalysis() {
  const results = [];
  for (const [merchant, data] of recurringCache.entries()) {
    if (data.isRecurring) {
      results.push(data);
    }
  }
  return results.sort((a, b) => b.avgAmount - a.avgAmount);
}

/**
 * Refreshes the recurring detection cache from a full transaction set.
 *
 * @param {Array<object>} allTransactions
 */
function refreshRecurringCache(allTransactions) {
  recurringCache = analyzeRecurring(allTransactions);
}

// MARK: — Client Output Formatting

/**
 * Formats a normalized transaction for the iOS client.
 * Maps internal fields to the expected client schema.
 *
 * @param {object} tx - Normalized transaction
 * @returns {object} Client-ready transaction
 */
function formatForClient(tx) {
  return {
    id: tx.id,
    date: tx.date,

    // Currency normalization fields
    amountOriginal: tx.amountOriginal,
    currencyOriginal: tx.currencyOriginal,
    amountConverted: tx.amountConverted,
    currencyBase: tx.currencyBase,
    exchangeRateAtTime: tx.exchangeRateAtTime,

    // Legacy compatibility
    amount: tx.amountConverted || tx.amount,

    // Merchant (canonical first, fallback to clean, then raw)
    merchant: tx.merchantName || tx.merchantClean || tx.merchantRaw || tx.name,
    merchantName: tx.merchantName || tx.merchantClean || tx.merchantRaw || tx.name,
    merchantRaw: tx.merchantRaw,

    // Classification
    category: tx.category,
    isRecurring: tx.isRecurring,
    recurringInterval: tx.recurringInterval || null,

    // Confidence (expose the dominant score for UI)
    confidence: resolveOverallConfidence(tx.confidenceScores),

    // Detailed confidence scores
    confidenceScores: tx.confidenceScores,
  };
}

// MARK: — Helpers

/**
 * Resolves the better of two confidence levels.
 * Used to combine cleaning + mapping confidence.
 *
 * @param {string} a
 * @param {string} b
 * @returns {string}
 */
function resolveConfidence(a, b) {
  const order = { high: 3, medium: 2, low: 1 };
  const scoreA = order[a] || 1;
  const scoreB = order[b] || 1;

  // If both contributed, take the higher
  if (scoreA >= 3 && scoreB >= 2) return "high";
  if (scoreA >= 2 || scoreB >= 2) return "medium";
  return "low";
}

/**
 * Resolves the overall confidence for client display.
 * Uses the minimum of all individual scores (weakest link).
 *
 * @param {object} scores - { merchant, category, recurring }
 * @returns {string}
 */
function resolveOverallConfidence(scores) {
  if (!scores) return "medium";

  const order = { high: 3, medium: 2, low: 1 };
  const merchantScore = order[scores.merchant] || 1;
  const categoryScore = order[scores.category] || 1;

  // Recurring confidence doesn't affect overall (it's optional)
  const minScore = Math.min(merchantScore, categoryScore);

  if (minScore >= 3) return "high";
  if (minScore >= 2) return "medium";
  return "low";
}

/**
 * Applies user-specific feedback overrides to a normalized transaction.
 * Checks both raw and canonical merchant names for overrides.
 *
 * @param {object} tx - Normalized transaction (mutated in place)
 * @param {string} userId - User identifier
 */
function applyUserOverrides(tx, userId) {
  // Check overrides against both the canonical name and raw name
  const override =
    getUserOverride(userId, tx.merchantName) ||
    getUserOverride(userId, tx.merchantRaw);

  if (!override) return;

  // Apply merchant override
  if (override.merchant && override.merchant !== tx.merchantName) {
    tx.merchantName = override.merchant;
    tx.confidenceScores.merchant = "high"; // User-corrected = high confidence
  }

  // Apply category override
  if (override.category && override.category !== tx.category) {
    tx.category = override.category;
    tx.confidenceScores.category = "high";
  }

  // Apply recurring override
  if (override.isRecurring !== null && override.isRecurring !== undefined) {
    tx.isRecurring = override.isRecurring;
    if (!override.isRecurring) {
      tx.recurringInterval = null;
    }
    tx.confidenceScores.recurring = "high";
  }
}

module.exports = {
  normalizeTransaction,
  normalizeBatch,
  getRecurringAnalysis,
  refreshRecurringCache,
  formatForClient,
  applyUserOverrides,
};
