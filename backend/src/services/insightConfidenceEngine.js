/**
 * @module insightConfidenceEngine
 *
 * Insight Confidence Engine
 *
 * Scores, filters, and adjusts all financial insights before they
 * are surfaced to the user. Acts as the quality gate between raw
 * insight generation and the client UI.
 *
 * Core principle: DO NOT show insights unless confidence meets threshold.
 *
 * Pipeline:
 * 1. Score — compute 0–100 confidence score from weighted factors
 * 2. Classify — map score to high / medium / low tier
 * 3. Filter — suppress low-confidence insights (showToUser = false)
 * 4. Adjust — rewrite message tone per confidence tier
 * 5. Annotate — attach reasoning for transparency / debugging
 *
 * Scoring factors (weighted):
 * - Merchant clarity      (25%) — how confidently we identified the merchant
 * - Category reliability  (20%) — classification confidence
 * - Recurrence strength   (25%) — recurring detection confidence
 * - Historical consistency (15%) — how many data points support the pattern
 * - Amount stability      (15%) — whether amounts are consistent
 *
 * Thresholds:
 * - High:   score >= 70 → Always show, assertive language
 * - Medium: score >= 40 → Show with hedged language ("Looks like...")
 * - Low:    score < 40  → Do NOT show, internal only
 *
 * Feedback Integration:
 * - Confirmed insights boost the merchant's confidence adjustment
 * - Corrected insights penalize the merchant's confidence adjustment
 * - Net adjustment from feedbackStore is applied to the final weighted score
 */

const { getConfidenceAdjustment } = require("./feedbackStore");

// MARK: — Scoring Weights

const SCORING_WEIGHTS = {
  merchantClarity: 0.25,
  categoryReliability: 0.20,
  recurrenceStrength: 0.25,
  historicalConsistency: 0.15,
  amountStability: 0.15,
};

// MARK: — Confidence Thresholds

const THRESHOLDS = {
  HIGH: 70,
  MEDIUM: 40,
};

// MARK: — Confidence Level Scores

/**
 * Maps string confidence levels to numeric scores (0–100 scale).
 */
const CONFIDENCE_SCORES = {
  high: 100,
  medium: 60,
  low: 20,
};

// MARK: — Tone Adjustment Templates

/**
 * Message templates per confidence tier.
 * Applied to insight descriptions to adjust language tone.
 */
const TONE_PREFIXES = {
  high: {
    subscription: "",                          // No prefix — assertive
    duplicate: "⚠️ ",
    spending: "",
    saving: "",
    general: "",
  },
  medium: {
    subscription: "Looks like ",
    duplicate: "You may have ",
    spending: "It appears ",
    saving: "You might be able to ",
    general: "We noticed ",
  },
  low: {
    subscription: "Possible ",
    duplicate: "Potential ",
    spending: "Possibly ",
    saving: "There may be ",
    general: "Unclear — ",
  },
};

/**
 * Maps insight types to tone categories.
 */
const TYPE_TO_TONE_CATEGORY = {
  subscription_increase: "subscription",
  duplicate_charge: "duplicate",
  unusual_spending: "spending",
  saving_opportunity: "saving",
  hidden_subscription: "subscription",
  price_increase: "subscription",
  income_volatility: "general",
  expense_cluster: "spending",
  opportunity_insight: "saving",
};

// MARK: — Public API

/**
 * Processes a batch of raw insights through the confidence pipeline.
 *
 * @param {Array<object>} rawInsights - Raw insights from intelligence engines
 * @param {Array<object>} transactions - Normalized transactions for context
 * @returns {Array<object>} Scored, filtered, and tone-adjusted insights
 */
function processInsights(rawInsights, transactions = []) {
  if (!rawInsights || rawInsights.length === 0) return [];

  const transactionContext = buildTransactionContext(transactions);

  return rawInsights.map((insight) => {
    const scored = scoreInsight(insight, transactionContext);
    const filtered = applyVisibilityFilter(scored);
    const adjusted = adjustMessageTone(filtered);
    return annotateReasoning(adjusted, transactionContext);
  });
}

/**
 * Filters a processed insight array to only user-visible insights.
 *
 * @param {Array<object>} processedInsights - Output of processInsights
 * @returns {Array<object>} Only insights where showToUser === true
 */
function filterForUser(processedInsights) {
  return processedInsights.filter((insight) => insight.showToUser === true);
}

/**
 * Scores a single raw insight.
 *
 * @param {object} insight - Raw insight
 * @param {object} context - Transaction context
 * @returns {object} Insight with confidenceScore (0–100) and confidence tier
 */
function scoreInsight(insight, context = {}) {
  const factors = extractScoringFactors(insight, context);
  let weightedScore = calculateWeightedScore(factors);

  // Apply feedback-based confidence adjustment
  const merchant = insight.merchant || insight.merchantName;
  if (merchant) {
    const feedbackAdj = getConfidenceAdjustment(merchant);
    weightedScore = Math.max(0, Math.min(100, weightedScore + feedbackAdj));
  }

  const tier = classifyTier(weightedScore);

  return {
    ...insight,
    confidenceScore: Math.round(weightedScore),
    confidence: tier,
    scoringFactors: factors,
  };
}

// MARK: — Scoring Logic

/**
 * Extracts individual scoring factors from an insight and its context.
 *
 * @param {object} insight
 * @param {object} context
 * @returns {object} Individual factor scores (0–100)
 */
function extractScoringFactors(insight, context) {
  // Merchant clarity — from the normalization confidence scores
  const merchantClarity = resolveFactorScore(
    insight.merchantConfidence || insight.confidenceScores?.merchant || insight.confidence
  );

  // Category reliability — from classification confidence
  const categoryReliability = resolveFactorScore(
    insight.categoryConfidence || insight.confidenceScores?.category || insight.confidence
  );

  // Recurrence strength — from recurring detection confidence
  const recurrenceStrength = resolveRecurrenceScore(insight, context);

  // Historical consistency — number of data points supporting the pattern
  const historicalConsistency = resolveHistoricalScore(insight, context);

  // Amount stability — consistency of amounts in related transactions
  const amountStability = resolveAmountStabilityScore(insight, context);

  return {
    merchantClarity,
    categoryReliability,
    recurrenceStrength,
    historicalConsistency,
    amountStability,
  };
}

/**
 * Converts a confidence level string to a numeric score.
 *
 * @param {string} level - "high", "medium", or "low"
 * @returns {number} 0–100
 */
function resolveFactorScore(level) {
  if (typeof level === "number") return Math.max(0, Math.min(100, level));
  return CONFIDENCE_SCORES[level] || CONFIDENCE_SCORES.low;
}

/**
 * Scores the recurrence factor based on insight type and context.
 *
 * - Subscription insights: use recurring detection confidence
 * - Duplicate insights: high if exact match, medium otherwise
 * - Other: neutral (60)
 *
 * @param {object} insight
 * @param {object} context
 * @returns {number} 0–100
 */
function resolveRecurrenceScore(insight, context) {
  const type = insight.type;

  // Subscription-related insights depend heavily on recurrence
  if (
    type === "subscription_increase" ||
    type === "hidden_subscription" ||
    type === "price_increase"
  ) {
    const recurringConf =
      insight.recurringConfidence ||
      insight.confidenceScores?.recurring ||
      null;

    if (recurringConf) {
      return resolveFactorScore(recurringConf);
    }

    // Fallback: check if the merchant exists in recurring context
    const merchant = insight.merchant || insight.merchantName;
    if (merchant && context.recurringMerchants?.has(merchant)) {
      return 85;
    }

    return 40; // Uncertain
  }

  // Duplicate charges: high confidence if same amount + same day
  if (type === "duplicate_charge") {
    return insight.duplicateCount >= 2 ? 90 : 60;
  }

  // Non-recurring insights: recurrence is neutral
  return 60;
}

/**
 * Scores historical consistency — more data points = higher confidence.
 *
 * @param {object} insight
 * @param {object} context
 * @returns {number} 0–100
 */
function resolveHistoricalScore(insight, context) {
  const merchant = insight.merchant || insight.merchantName;
  if (!merchant) return 30;

  const occurrences = context.merchantOccurrences?.get(merchant) || 0;

  if (occurrences >= 6) return 100;
  if (occurrences >= 4) return 80;
  if (occurrences >= 3) return 60;
  if (occurrences >= 2) return 40;
  return 20;
}

/**
 * Scores amount stability — consistent amounts across occurrences.
 *
 * @param {object} insight
 * @param {object} context
 * @returns {number} 0–100
 */
function resolveAmountStabilityScore(insight, context) {
  const merchant = insight.merchant || insight.merchantName;
  if (!merchant) return 50;

  const amounts = context.merchantAmounts?.get(merchant) || [];
  if (amounts.length < 2) return 50; // Not enough data

  const mean = amounts.reduce((s, a) => s + a, 0) / amounts.length;
  if (mean === 0) return 50;

  const variance =
    amounts.reduce((s, a) => s + Math.pow(a - mean, 2), 0) / amounts.length;
  const cv = Math.sqrt(variance) / mean; // coefficient of variation

  if (cv < 0.05) return 100; // Very stable
  if (cv < 0.10) return 85;
  if (cv < 0.20) return 65;
  if (cv < 0.40) return 40;
  return 20; // Highly variable
}

/**
 * Calculates the final weighted score from individual factors.
 *
 * @param {object} factors - Individual factor scores (0–100)
 * @returns {number} Weighted score (0–100)
 */
function calculateWeightedScore(factors) {
  let total = 0;

  for (const [key, weight] of Object.entries(SCORING_WEIGHTS)) {
    const factorScore = factors[key] || 0;
    total += factorScore * weight;
  }

  return total;
}

/**
 * Classifies a numeric score into a confidence tier.
 *
 * @param {number} score - 0–100
 * @returns {string} "high" | "medium" | "low"
 */
function classifyTier(score) {
  if (score >= THRESHOLDS.HIGH) return "high";
  if (score >= THRESHOLDS.MEDIUM) return "medium";
  return "low";
}

// MARK: — Filtering

/**
 * Applies the visibility filter based on confidence tier.
 *
 * - high/medium → showToUser: true
 * - low → showToUser: false (internal only)
 *
 * @param {object} insight - Scored insight
 * @returns {object} Insight with showToUser flag
 */
function applyVisibilityFilter(insight) {
  return {
    ...insight,
    showToUser: insight.confidence !== "low",
  };
}

// MARK: — Tone Adjustment

/**
 * Adjusts the insight message tone based on confidence tier.
 *
 * - High: assertive, direct language
 * - Medium: hedged language ("Looks like...", "You may...")
 * - Low: kept as-is (won't be shown anyway)
 *
 * @param {object} insight - Scored insight with confidence tier
 * @returns {object} Insight with adjusted message
 */
function adjustMessageTone(insight) {
  const tier = insight.confidence;
  const type = insight.type;
  const toneCategory = TYPE_TO_TONE_CATEGORY[type] || "general";
  const prefix = TONE_PREFIXES[tier]?.[toneCategory] || "";

  // Only adjust for medium tier — high is already assertive, low won't show
  if (tier === "medium") {
    const originalMessage = insight.message || insight.description || "";

    // Don't double-prefix if the message already starts with hedging language
    const hedgePhrases = ["looks like", "you may", "it appears", "possible", "we noticed"];
    const lowerMsg = originalMessage.toLowerCase();
    const alreadyHedged = hedgePhrases.some((phrase) => lowerMsg.startsWith(phrase));

    if (!alreadyHedged && prefix) {
      // Lowercase the first character of the original message for smooth concatenation
      const adjustedMessage =
        prefix + originalMessage.charAt(0).toLowerCase() + originalMessage.slice(1);

      return {
        ...insight,
        message: adjustedMessage,
        originalMessage,
      };
    }
  }

  return {
    ...insight,
    message: insight.message || insight.description || "",
    originalMessage: insight.message || insight.description || "",
  };
}

// MARK: — Reasoning Annotation

/**
 * Attaches a human-readable reasoning string to explain
 * why the confidence score was assigned.
 *
 * @param {object} insight - Scored and filtered insight
 * @param {object} context - Transaction context
 * @returns {object} Insight with reasoning field
 */
function annotateReasoning(insight, context) {
  const factors = insight.scoringFactors || {};
  const reasons = [];

  // Merchant clarity
  if (factors.merchantClarity >= 80) {
    reasons.push("Merchant identity verified with high confidence");
  } else if (factors.merchantClarity >= 50) {
    reasons.push("Merchant partially matched — some uncertainty");
  } else {
    reasons.push("Merchant identity unclear");
  }

  // Recurrence
  if (factors.recurrenceStrength >= 80) {
    reasons.push("Strong recurring billing pattern detected");
  } else if (factors.recurrenceStrength >= 50) {
    reasons.push("Possible recurring pattern — needs more data");
  }

  // Historical depth
  const merchant = insight.merchant || insight.merchantName;
  const occurrences = context.merchantOccurrences?.get(merchant) || 0;
  if (occurrences >= 4) {
    reasons.push(`Supported by ${occurrences} historical transactions`);
  } else if (occurrences >= 2) {
    reasons.push(`Limited history: only ${occurrences} occurrences`);
  } else {
    reasons.push("Insufficient transaction history");
  }

  // Amount stability
  if (factors.amountStability >= 80) {
    reasons.push("Amounts are highly consistent across charges");
  } else if (factors.amountStability < 40) {
    reasons.push("Amounts vary significantly — may indicate irregular charges");
  }

  // Visibility
  if (!insight.showToUser) {
    reasons.push("Below confidence threshold — suppressed from user view");
  }

  return {
    ...insight,
    reasoning: reasons.join(". ") + ".",
  };
}

// MARK: — Transaction Context Builder

/**
 * Builds an analysis context from the full transaction set.
 * Pre-computes per-merchant stats used by scoring factors.
 *
 * @param {Array<object>} transactions
 * @returns {object} Context with merchant stats
 */
function buildTransactionContext(transactions) {
  const merchantOccurrences = new Map();
  const merchantAmounts = new Map();
  const recurringMerchants = new Set();

  for (const tx of transactions) {
    const merchant = tx.merchantName || tx.merchant || tx.name;
    if (!merchant) continue;

    // Count occurrences
    merchantOccurrences.set(
      merchant,
      (merchantOccurrences.get(merchant) || 0) + 1
    );

    // Collect amounts
    if (!merchantAmounts.has(merchant)) {
      merchantAmounts.set(merchant, []);
    }
    merchantAmounts.get(merchant).push(Math.abs(tx.amountConverted || tx.amount || 0));

    // Track recurring merchants
    if (tx.isRecurring) {
      recurringMerchants.add(merchant);
    }
  }

  return {
    merchantOccurrences,
    merchantAmounts,
    recurringMerchants,
    totalTransactions: transactions.length,
  };
}

// MARK: — Insight Generation (Backend)

/**
 * Generates scored insights from normalized transactions.
 *
 * This is the backend equivalent of the iOS FinancialIntelligenceEngine.
 * Produces insights that are already scored, filtered, and ready for the client.
 *
 * @param {Array<object>} transactions - Normalized transactions from the store
 * @returns {Array<object>} Scored insights in client-ready format
 */
function generateInsights(transactions) {
  if (!transactions || transactions.length === 0) return [];

  const rawInsights = [];

  // 1. Subscription price increases
  rawInsights.push(...detectSubscriptionIncreases(transactions));

  // 2. Duplicate charges
  rawInsights.push(...detectDuplicateCharges(transactions));

  // 3. Unused subscriptions
  rawInsights.push(...detectUnusedSubscriptions(transactions));

  // 4. Unusual spending spikes
  rawInsights.push(...detectUnusualSpending(transactions));

  // Score and filter all insights
  return processInsights(rawInsights, transactions);
}

/**
 * Detects subscription price increases.
 *
 * @param {Array<object>} transactions
 * @returns {Array<object>} Raw insights
 */
function detectSubscriptionIncreases(transactions) {
  const insights = [];
  const recurring = transactions.filter((tx) => tx.isRecurring);
  const grouped = groupBy(recurring, (tx) => tx.merchantName || tx.merchant);

  for (const [merchant, txs] of Object.entries(grouped)) {
    const sorted = txs.sort((a, b) => new Date(b.date) - new Date(a.date));

    if (sorted.length >= 2) {
      const latest = Math.abs(sorted[0].amountConverted || sorted[0].amount);
      const previous = Math.abs(sorted[1].amountConverted || sorted[1].amount);

      if (latest > previous && latest - previous > 0.50) {
        const increase = latest - previous;

        insights.push({
          id: generateId(),
          type: "subscription_increase",
          title: "Bill Increase Alert",
          message: `${merchant} increased by $${increase.toFixed(2)}/month. That's $${(increase * 12).toFixed(2)}/year extra.`,
          description: `${merchant} increased by $${increase.toFixed(2)}/month.`,
          merchant,
          merchantName: merchant,
          monthlyImpact: increase,
          annualImpact: increase * 12,
          primaryAction: "negotiate",
          confidence: "high",
          merchantConfidence: sorted[0].confidenceScores?.merchant || "high",
          categoryConfidence: sorted[0].confidenceScores?.category || "high",
          recurringConfidence: sorted[0].confidenceScores?.recurring || "high",
          duplicateCount: 0,
        });
      }
    }
  }

  return insights;
}

/**
 * Detects duplicate charges — same merchant, same amount, same day.
 *
 * @param {Array<object>} transactions
 * @returns {Array<object>} Raw insights
 */
function detectDuplicateCharges(transactions) {
  const insights = [];
  const now = new Date();
  const threeDaysAgo = new Date(now);
  threeDaysAgo.setDate(threeDaysAgo.getDate() - 3);

  const recent = transactions.filter((tx) => new Date(tx.date) >= threeDaysAgo);
  const grouped = groupBy(
    recent,
    (tx) => `${tx.merchantName || tx.merchant}-${Math.abs(tx.amountConverted || tx.amount)}-${tx.date}`
  );

  for (const [key, txs] of Object.entries(grouped)) {
    if (txs.length >= 2) {
      const merchant = txs[0].merchantName || txs[0].merchant;
      const amount = Math.abs(txs[0].amountConverted || txs[0].amount);

      insights.push({
        id: generateId(),
        type: "duplicate_charge",
        title: "Duplicate Charge Detected",
        message: `You were charged $${amount.toFixed(2)} twice for ${merchant}. Review and dispute.`,
        description: `Duplicate $${amount.toFixed(2)} charge at ${merchant}.`,
        merchant,
        merchantName: merchant,
        monthlyImpact: amount,
        annualImpact: amount,
        primaryAction: "review",
        confidence: "high",
        merchantConfidence: txs[0].confidenceScores?.merchant || "high",
        categoryConfidence: txs[0].confidenceScores?.category || "medium",
        recurringConfidence: "low",
        duplicateCount: txs.length,
      });
    }
  }

  return insights;
}

/**
 * Detects potentially unused subscriptions.
 * A subscription is "unused" if it's recurring but there's no
 * non-subscription activity with the same merchant.
 *
 * @param {Array<object>} transactions
 * @returns {Array<object>} Raw insights
 */
function detectUnusedSubscriptions(transactions) {
  const insights = [];
  const now = new Date();
  const thirtyDaysAgo = new Date(now);
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

  const recurring = transactions.filter((tx) => tx.isRecurring);
  const grouped = groupBy(recurring, (tx) => tx.merchantName || tx.merchant);

  for (const [merchant, txs] of Object.entries(grouped)) {
    // Check if only subscription charges, no other activity
    const recentCharges = txs.filter((tx) => new Date(tx.date) >= thirtyDaysAgo);

    if (recentCharges.length === 0 && txs.length >= 2) {
      const lastAmount = Math.abs(txs[0].amountConverted || txs[0].amount);

      insights.push({
        id: generateId(),
        type: "hidden_subscription",
        title: "Unused Subscription",
        message: `No recent activity from ${merchant} ($${lastAmount.toFixed(2)}/month). Consider canceling.`,
        description: `${merchant} subscription may be unused.`,
        merchant,
        merchantName: merchant,
        monthlyImpact: lastAmount,
        annualImpact: lastAmount * 12,
        primaryAction: "cancel",
        confidence: "medium",
        merchantConfidence: txs[0].confidenceScores?.merchant || "medium",
        categoryConfidence: txs[0].confidenceScores?.category || "medium",
        recurringConfidence: txs[0].confidenceScores?.recurring || "medium",
        duplicateCount: 0,
      });
    }
  }

  return insights;
}

/**
 * Detects unusual spending spikes in specific categories.
 *
 * @param {Array<object>} transactions
 * @returns {Array<object>} Raw insights
 */
function detectUnusualSpending(transactions) {
  const insights = [];
  const now = new Date();
  const thirtyDaysAgo = new Date(now);
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
  const sixtyDaysAgo = new Date(now);
  sixtyDaysAgo.setDate(sixtyDaysAgo.getDate() - 60);

  // Compare current month vs previous month per category
  const currentMonth = transactions.filter(
    (tx) => new Date(tx.date) >= thirtyDaysAgo && Math.abs(tx.amountConverted || tx.amount) > 0
  );
  const previousMonth = transactions.filter(
    (tx) => new Date(tx.date) >= sixtyDaysAgo && new Date(tx.date) < thirtyDaysAgo
  );

  const currentByCategory = groupBy(currentMonth, (tx) => tx.category);
  const previousByCategory = groupBy(previousMonth, (tx) => tx.category);

  for (const [category, txs] of Object.entries(currentByCategory)) {
    if (category === "income" || category === "other") continue;

    const currentTotal = txs.reduce((s, tx) => s + Math.abs(tx.amountConverted || tx.amount), 0);
    const prevTxs = previousByCategory[category] || [];
    const previousTotal = prevTxs.reduce((s, tx) => s + Math.abs(tx.amountConverted || tx.amount), 0);

    // Flag if current month is 50%+ higher than previous
    if (previousTotal > 0 && currentTotal > previousTotal * 1.5 && currentTotal - previousTotal > 50) {
      const increase = currentTotal - previousTotal;

      insights.push({
        id: generateId(),
        type: "unusual_spending",
        title: "Spending Spike",
        message: `Your ${category} spending is up $${increase.toFixed(2)} compared to last month.`,
        description: `${category} spending increased significantly.`,
        merchant: null,
        merchantName: null,
        monthlyImpact: increase,
        annualImpact: increase * 12,
        primaryAction: "review",
        confidence: "medium",
        merchantConfidence: "medium",
        categoryConfidence: "medium",
        recurringConfidence: "low",
        duplicateCount: 0,
      });
    }
  }

  return insights;
}

// MARK: — Helpers

/**
 * Groups an array by a key function.
 *
 * @param {Array} arr
 * @param {Function} keyFn
 * @returns {object}
 */
function groupBy(arr, keyFn) {
  const groups = {};
  for (const item of arr) {
    const key = keyFn(item) || "unknown";
    if (!groups[key]) groups[key] = [];
    groups[key].push(item);
  }
  return groups;
}

/**
 * Generates a simple unique ID for insights.
 *
 * @returns {string}
 */
function generateId() {
  return `insight_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`;
}

module.exports = {
  processInsights,
  filterForUser,
  scoreInsight,
  generateInsights,
  buildTransactionContext,
  THRESHOLDS,
};
