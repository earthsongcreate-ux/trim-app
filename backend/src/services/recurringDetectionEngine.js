/**
 * @module recurringDetectionEngine
 *
 * Recurring / Subscription Detection Engine
 *
 * Analyzes transaction history to detect recurring billing patterns.
 *
 * Detection strategy:
 * 1. Group transactions by canonical merchant name
 * 2. Sort by date within each group
 * 3. Calculate intervals between consecutive charges
 * 4. Detect consistent interval patterns (monthly, yearly, weekly, etc.)
 * 5. Assign confidence based on consistency and sample size
 *
 * Design decisions:
 * - Minimum 2 occurrences required to flag as potentially recurring
 * - Interval tolerance: ±3 days for monthly, ±7 days for yearly
 * - Amount consistency is checked — varying amounts lower confidence
 * - Results are stored per-merchant, not per-transaction
 *
 * Output feeds into:
 * - FinancialIntelligenceEngine (subscription increase alerts)
 * - SavingsDashboard (subscription cost summaries)
 * - InsightsView (unused subscription detection)
 */

// MARK: — Interval Definitions

/**
 * Known billing intervals with their expected day counts and tolerance windows.
 */
const INTERVALS = {
  weekly: { days: 7, tolerance: 2, label: "weekly" },
  biweekly: { days: 14, tolerance: 3, label: "bi-weekly" },
  monthly: { days: 30, tolerance: 4, label: "monthly" },
  quarterly: { days: 90, tolerance: 10, label: "quarterly" },
  semiannual: { days: 182, tolerance: 14, label: "semi-annual" },
  annual: { days: 365, tolerance: 14, label: "annual" },
};

// MARK: — Public API

/**
 * Analyzes a set of transactions and returns recurring billing results
 * grouped by merchant.
 *
 * @param {Array<object>} transactions - Normalized transactions with:
 *   { merchantName: string, date: string, amountConverted: number }
 * @returns {Map<string, RecurringResult>} merchant → detection result
 *
 * RecurringResult shape:
 * {
 *   merchant:     string,
 *   isRecurring:  boolean,
 *   interval:     string | null,   ("monthly", "annual", etc.)
 *   confidence:   string,          ("high", "medium", "low")
 *   occurrences:  number,
 *   avgAmount:    number,
 *   lastCharged:  string,          (ISO date)
 *   nextExpected: string | null,   (predicted next charge date)
 *   amountStable: boolean,         (whether amounts are consistent)
 * }
 */
function analyzeRecurring(transactions) {
  const results = new Map();

  if (!transactions || transactions.length === 0) {
    return results;
  }

  // Step 1: Group by canonical merchant name
  const groups = groupByMerchant(transactions);

  // Step 2: Analyze each group
  for (const [merchant, txs] of groups.entries()) {
    const result = analyzeGroup(merchant, txs);
    results.set(merchant, result);
  }

  return results;
}

/**
 * Checks a single transaction against existing recurring analysis.
 * Used during ingest to flag new transactions as recurring.
 *
 * @param {object} transaction - The transaction to check
 * @param {Map<string, RecurringResult>} recurringMap - Output of analyzeRecurring
 * @returns {{ isRecurring: boolean, interval: string|null, confidence: string }}
 */
function checkTransaction(transaction, recurringMap) {
  const merchant = transaction.merchantName || transaction.name || "";

  if (!merchant || !recurringMap) {
    return { isRecurring: false, interval: null, confidence: "low" };
  }

  const result = recurringMap.get(merchant);
  if (result && result.isRecurring) {
    return {
      isRecurring: true,
      interval: result.interval,
      confidence: result.confidence,
    };
  }

  return { isRecurring: false, interval: null, confidence: "low" };
}

/**
 * Predicts the next expected charge date for a recurring merchant.
 *
 * @param {string} lastDate - ISO date string of last charge
 * @param {string} interval - Interval type ("monthly", "annual", etc.)
 * @returns {string|null} Predicted next date (ISO) or null
 */
function predictNextCharge(lastDate, interval) {
  if (!lastDate || !interval) return null;

  const intervalDef = INTERVALS[interval];
  if (!intervalDef) return null;

  const last = new Date(lastDate);
  if (isNaN(last.getTime())) return null;

  const next = new Date(last);
  next.setDate(next.getDate() + intervalDef.days);

  return next.toISOString().split("T")[0];
}

// MARK: — Internal Logic

/**
 * Groups transactions by merchant name.
 *
 * @param {Array<object>} transactions
 * @returns {Map<string, Array<object>>}
 */
function groupByMerchant(transactions) {
  const groups = new Map();

  for (const tx of transactions) {
    const merchant = tx.merchantName || tx.name || "Unknown";
    if (!groups.has(merchant)) {
      groups.set(merchant, []);
    }
    groups.get(merchant).push(tx);
  }

  return groups;
}

/**
 * Analyzes a single merchant's transaction group for recurrence.
 *
 * @param {string} merchant
 * @param {Array<object>} txs - Transactions sorted by date
 * @returns {RecurringResult}
 */
function analyzeGroup(merchant, txs) {
  // Sort by date ascending
  const sorted = [...txs].sort(
    (a, b) => new Date(a.date) - new Date(b.date)
  );

  const occurrences = sorted.length;
  const amounts = sorted.map((tx) => Math.abs(tx.amountConverted || tx.amount || 0));
  const avgAmount = amounts.reduce((sum, a) => sum + a, 0) / amounts.length;
  const lastCharged = sorted[sorted.length - 1].date;

  // Need at least 2 occurrences to detect patterns
  if (occurrences < 2) {
    return {
      merchant,
      isRecurring: false,
      interval: null,
      confidence: "low",
      occurrences,
      avgAmount: Math.round(avgAmount * 100) / 100,
      lastCharged,
      nextExpected: null,
      amountStable: true,
    };
  }

  // Calculate intervals between consecutive transactions
  const intervals = [];
  for (let i = 1; i < sorted.length; i++) {
    const prev = new Date(sorted[i - 1].date);
    const curr = new Date(sorted[i].date);
    const daysDiff = Math.round((curr - prev) / (1000 * 60 * 60 * 24));
    intervals.push(daysDiff);
  }

  // Detect interval pattern
  const detectedInterval = detectInterval(intervals);

  // Check amount stability
  const amountStable = checkAmountStability(amounts);

  // Calculate confidence
  const confidence = calculateConfidence(
    occurrences,
    detectedInterval,
    amountStable,
    intervals
  );

  const isRecurring = detectedInterval !== null && confidence !== "low";

  return {
    merchant,
    isRecurring,
    interval: detectedInterval,
    confidence,
    occurrences,
    avgAmount: Math.round(avgAmount * 100) / 100,
    lastCharged,
    nextExpected: isRecurring
      ? predictNextCharge(lastCharged, detectedInterval)
      : null,
    amountStable,
  };
}

/**
 * Detects the most likely billing interval from a set of day-gaps.
 *
 * @param {number[]} gaps - Days between consecutive charges
 * @returns {string|null} Interval name or null
 */
function detectInterval(gaps) {
  if (gaps.length === 0) return null;

  const avgGap = gaps.reduce((sum, g) => sum + g, 0) / gaps.length;

  // Test each known interval
  for (const [name, def] of Object.entries(INTERVALS)) {
    const matchingGaps = gaps.filter(
      (g) => Math.abs(g - def.days) <= def.tolerance
    );

    // At least 60% of gaps should match this interval
    const matchRatio = matchingGaps.length / gaps.length;
    if (matchRatio >= 0.6) {
      return name;
    }
  }

  // Check if the average gap is close to any known interval
  for (const [name, def] of Object.entries(INTERVALS)) {
    if (Math.abs(avgGap - def.days) <= def.tolerance) {
      return name;
    }
  }

  return null;
}

/**
 * Checks whether amounts across occurrences are relatively stable.
 * Stable = standard deviation < 15% of mean.
 *
 * @param {number[]} amounts
 * @returns {boolean}
 */
function checkAmountStability(amounts) {
  if (amounts.length <= 1) return true;

  const mean = amounts.reduce((s, a) => s + a, 0) / amounts.length;
  if (mean === 0) return true;

  const variance =
    amounts.reduce((s, a) => s + Math.pow(a - mean, 2), 0) / amounts.length;
  const stdDev = Math.sqrt(variance);
  const cv = stdDev / mean; // coefficient of variation

  return cv < 0.15;
}

/**
 * Calculates overall confidence for the recurring detection.
 *
 * @param {number} occurrences
 * @param {string|null} interval
 * @param {boolean} amountStable
 * @param {number[]} gaps
 * @returns {string} "high" | "medium" | "low"
 */
function calculateConfidence(occurrences, interval, amountStable, gaps) {
  if (!interval) return "low";

  let score = 0;

  // More occurrences = higher confidence
  if (occurrences >= 6) score += 3;
  else if (occurrences >= 4) score += 2;
  else if (occurrences >= 2) score += 1;

  // Amount stability boosts confidence
  if (amountStable) score += 2;

  // Interval consistency
  const intervalDef = INTERVALS[interval];
  if (intervalDef) {
    const consistentGaps = gaps.filter(
      (g) => Math.abs(g - intervalDef.days) <= intervalDef.tolerance
    );
    const consistency = consistentGaps.length / gaps.length;

    if (consistency >= 0.9) score += 3;
    else if (consistency >= 0.7) score += 2;
    else if (consistency >= 0.5) score += 1;
  }

  if (score >= 6) return "high";
  if (score >= 3) return "medium";
  return "low";
}

module.exports = {
  analyzeRecurring,
  checkTransaction,
  predictNextCharge,
  INTERVALS,
};
