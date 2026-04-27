/**
 * @module financialScoreEngine
 *
 * Financial Health Score Engine
 *
 * Computes a single 0–100 score representing overall financial health.
 * The score is a weighted composite of five independent factors:
 *
 *   1. Subscription Efficiency (25%)
 *      - Unused subscriptions penalize
 *      - Price increases penalize
 *      - Duplicate charges penalize
 *
 *   2. Spending Stability (25%)
 *      - Sudden spikes penalize
 *      - Irregular patterns penalize
 *      - Consistent spending rewards
 *
 *   3. Savings Opportunities (20%)
 *      - Identified savings count
 *      - Acted-on savings reward
 *
 *   4. Income vs Expense Balance (20%)
 *      - Positive net cash flow rewards
 *      - Negative trend penalizes
 *
 *   5. Financial Behavior (10%)
 *      - Feedback engagement rewards
 *      - Acting on insights rewards
 *
 * Score ranges:
 *   0–40  → "Critical" (red)
 *   41–70 → "Fair"     (yellow)
 *   71–100 → "Good"    (green)
 *
 * Trend detection:
 *   Compares current month's factor scores against previous month's.
 *   "up" / "down" / "stable" (±3 point deadband)
 */

const { getFeedbackStats } = require("./feedbackStore");

// MARK: — Factor Weights

const FACTOR_WEIGHTS = {
  subscriptions: 0.25,
  spending: 0.25,
  savings: 0.20,
  cashflow: 0.20,
  behavior: 0.10,
};

// MARK: — Score History (for trend detection)

/**
 * Stores the last computed score per user for trend detection.
 * Map<userId, { score, factors, timestamp }>
 */
const scoreHistory = new Map();

// MARK: — Public API

/**
 * Computes the full financial health score for a user.
 *
 * @param {object} params
 * @param {Array<object>} params.transactions - All user transactions
 * @param {Array<object>} params.subscriptions - User's active subscriptions
 * @param {Array<object>} params.insights - Generated insights (all, including suppressed)
 * @param {string} [params.userId] - User identifier for trend tracking
 * @returns {object} Full health score result
 */
function calculateHealthScore({
  transactions = [],
  subscriptions = [],
  insights = [],
  userId = "default",
}) {
  // Calculate each factor independently
  const factors = {
    subscriptions: scoreSubscriptionEfficiency(subscriptions, insights),
    spending: scoreSpendingStability(transactions),
    savings: scoreSavingsOpportunities(insights),
    cashflow: scoreCashflowBalance(transactions),
    behavior: scoreBehavior(userId),
  };

  // Weighted composite score
  const score = Math.round(
    factors.subscriptions * FACTOR_WEIGHTS.subscriptions +
    factors.spending * FACTOR_WEIGHTS.spending +
    factors.savings * FACTOR_WEIGHTS.savings +
    factors.cashflow * FACTOR_WEIGHTS.cashflow +
    factors.behavior * FACTOR_WEIGHTS.behavior
  );

  const clampedScore = Math.max(0, Math.min(100, score));
  const status = classifyStatus(clampedScore);
  const trend = detectTrend(userId, clampedScore);

  // Store for future trend comparisons
  scoreHistory.set(userId, {
    score: clampedScore,
    factors,
    timestamp: new Date().toISOString(),
  });

  return {
    score: clampedScore,
    status,
    factors,
    trend,
    computedAt: new Date().toISOString(),
  };
}

// MARK: — Factor 1: Subscription Efficiency (0–100)

/**
 * Evaluates subscription health.
 *
 * Penalties:
 * - Each unused subscription: -12 points
 * - Each price-increase insight: -8 points
 * - Each duplicate-charge insight: -15 points
 *
 * @param {Array<object>} subscriptions
 * @param {Array<object>} insights
 * @returns {number} 0–100
 */
function scoreSubscriptionEfficiency(subscriptions, insights) {
  if (subscriptions.length === 0) return 85; // No subs = mostly healthy default

  let score = 100;

  // Penalize unused subscriptions
  const unused = subscriptions.filter((s) => s.isUnused);
  score -= unused.length * 12;

  // Penalize price increases (from insights)
  const priceIncreases = insights.filter(
    (i) => i.type === "subscriptionIncrease" || i.type === "subscription_increase"
  );
  score -= priceIncreases.length * 8;

  // Penalize duplicate charges
  const duplicates = insights.filter(
    (i) => i.type === "duplicateCharge" || i.type === "duplicate_charge"
  );
  score -= duplicates.length * 15;

  // Reward: ratio of actively-used subscriptions
  const activeRatio = subscriptions.length > 0
    ? (subscriptions.length - unused.length) / subscriptions.length
    : 1;
  score += activeRatio * 10;

  return clamp(score);
}

// MARK: — Factor 2: Spending Stability (0–100)

/**
 * Measures spending consistency and flags volatility.
 *
 * Strategy:
 * - Group transactions by month
 * - Calculate coefficient of variation (CV) of monthly totals
 * - Low CV → stable → high score
 * - Detect spikes: any month >1.5x the average is a spike
 *
 * @param {Array<object>} transactions
 * @returns {number} 0–100
 */
function scoreSpendingStability(transactions) {
  if (transactions.length < 5) return 70; // Not enough data

  // Group spending by month (exclude income)
  const monthlySpending = groupByMonth(
    transactions.filter((tx) => {
      const amount = tx.amountConverted || tx.amount || 0;
      return amount < 0 || tx.category !== "income";
    })
  );

  const months = Object.values(monthlySpending);
  if (months.length < 2) return 75; // Not enough months

  const mean = months.reduce((sum, v) => sum + v, 0) / months.length;
  if (mean === 0) return 80;

  // Coefficient of variation
  const variance = months.reduce((sum, v) => sum + Math.pow(v - mean, 2), 0) / months.length;
  const stdDev = Math.sqrt(variance);
  const cv = stdDev / Math.abs(mean);

  // CV < 0.15 → very stable (100)
  // CV > 0.6  → very unstable (30)
  let score = 100 - Math.min(70, cv * 100);

  // Spike detection: any month > 1.5x average
  const spikeCount = months.filter((m) => m > Math.abs(mean) * 1.5).length;
  score -= spikeCount * 8;

  return clamp(score);
}

// MARK: — Factor 3: Savings Opportunities (0–100)

/**
 * Scores how well the user acts on identified savings.
 *
 * - More identified savings = more room to improve
 * - Saving opportunities with primaryAction = "cancel" or "negotiate"
 *   that remain unacted are a penalty
 * - Having few unacted opportunities = high score
 *
 * @param {Array<object>} insights
 * @returns {number} 0–100
 */
function scoreSavingsOpportunities(insights) {
  const savingInsights = insights.filter(
    (i) =>
      i.type === "savingOpportunity" ||
      i.type === "saving_opportunity" ||
      i.type === "subscriptionIncrease" ||
      i.type === "subscription_increase"
  );

  if (savingInsights.length === 0) return 90; // No opportunities = doing well

  // Calculate total potential savings
  const totalPotential = savingInsights.reduce(
    (sum, i) => sum + (i.annualImpact || i.monthlyImpact * 12 || 0),
    0
  );

  // More unrealized potential = lower score
  // $0 potential = 90, $500+ potential = 40
  const penaltyFactor = Math.min(50, (totalPotential / 500) * 50);
  const score = 90 - penaltyFactor;

  return clamp(score);
}

// MARK: — Factor 4: Income vs Expense Balance (0–100)

/**
 * Evaluates net cash flow health.
 *
 * - Positive monthly surplus → high score
 * - Negative monthly balance → low score
 * - Trending worse → additional penalty
 *
 * @param {Array<object>} transactions
 * @returns {number} 0–100
 */
function scoreCashflowBalance(transactions) {
  if (transactions.length < 5) return 65; // Not enough data

  // Separate income vs expenses
  const income = transactions.filter(
    (tx) => tx.category === "income" || (tx.amountConverted || tx.amount || 0) > 0
  );
  const expenses = transactions.filter(
    (tx) => tx.category !== "income" && (tx.amountConverted || tx.amount || 0) <= 0
  );

  const totalIncome = income.reduce(
    (sum, tx) => sum + Math.abs(tx.amountConverted || tx.amount || 0),
    0
  );
  const totalExpenses = expenses.reduce(
    (sum, tx) => sum + Math.abs(tx.amountConverted || tx.amount || 0),
    0
  );

  if (totalIncome === 0) return 40; // No income detected

  // Expense-to-income ratio
  const ratio = totalExpenses / totalIncome;

  // ratio < 0.5 → excellent (100)
  // ratio = 1.0 → breakeven (50)
  // ratio > 1.2 → overspending (20)
  let score;
  if (ratio <= 0.5) {
    score = 100;
  } else if (ratio <= 0.8) {
    score = 100 - ((ratio - 0.5) / 0.3) * 20; // 100→80
  } else if (ratio <= 1.0) {
    score = 80 - ((ratio - 0.8) / 0.2) * 30; // 80→50
  } else {
    score = Math.max(10, 50 - ((ratio - 1.0) / 0.5) * 40); // 50→10
  }

  // Monthly trend analysis
  const monthlyNet = calculateMonthlyNetFlow(transactions);
  const months = Object.values(monthlyNet);
  if (months.length >= 3) {
    const recent = months.slice(-3);
    const isDecreasing = recent[2] < recent[1] && recent[1] < recent[0];
    if (isDecreasing) score -= 10; // Worsening trend
  }

  return clamp(score);
}

// MARK: — Factor 5: Financial Behavior (0–100)

/**
 * Scores user engagement with the system.
 *
 * - Feedback submissions (confirm/correct) → engaged user
 * - Higher accuracy rate → system is working well
 * - No feedback → neutral (not penalized heavily)
 *
 * @param {string} userId
 * @returns {number} 0–100
 */
function scoreBehavior(userId) {
  const stats = getFeedbackStats();

  // No feedback → baseline score
  if (stats.totalFeedback === 0) return 70;

  let score = 60; // Base for engaged users

  // Reward feedback volume (up to +20)
  score += Math.min(20, stats.totalFeedback * 2);

  // Reward high accuracy (system confidence)
  // If user confirms most things, the system is accurate
  if (stats.accuracy >= 80) score += 15;
  else if (stats.accuracy >= 60) score += 8;
  else score -= 5; // Low accuracy = system needs work

  // Reward corrections (shows engagement even if system was wrong)
  score += Math.min(5, stats.corrections);

  return clamp(score);
}

// MARK: — Status Classification

/**
 * Maps a numeric score to a human-readable status.
 *
 * @param {number} score
 * @returns {string}
 */
function classifyStatus(score) {
  if (score >= 85) return "Excellent";
  if (score >= 71) return "Good";
  if (score >= 55) return "Fair";
  if (score >= 41) return "Needs Attention";
  return "Critical";
}

// MARK: — Trend Detection

/**
 * Detects whether the score is trending up, down, or stable.
 * Uses a ±3 point deadband to avoid noise.
 *
 * @param {string} userId
 * @param {number} currentScore
 * @returns {string} "up" | "down" | "stable"
 */
function detectTrend(userId, currentScore) {
  const previous = scoreHistory.get(userId);
  if (!previous) return "stable";

  const diff = currentScore - previous.score;
  if (diff > 3) return "up";
  if (diff < -3) return "down";
  return "stable";
}

// MARK: — Helpers

/**
 * Groups transactions by YYYY-MM and sums absolute amounts.
 *
 * @param {Array<object>} transactions
 * @returns {object} { "2026-01": 1234.56, ... }
 */
function groupByMonth(transactions) {
  const months = {};
  for (const tx of transactions) {
    const monthKey = (tx.date || "").substring(0, 7); // "YYYY-MM"
    if (!monthKey) continue;
    const amount = Math.abs(tx.amountConverted || tx.amount || 0);
    months[monthKey] = (months[monthKey] || 0) + amount;
  }
  return months;
}

/**
 * Calculates net cash flow (income - expenses) per month.
 *
 * @param {Array<object>} transactions
 * @returns {object} { "2026-01": 500, "2026-02": -200, ... }
 */
function calculateMonthlyNetFlow(transactions) {
  const months = {};
  for (const tx of transactions) {
    const monthKey = (tx.date || "").substring(0, 7);
    if (!monthKey) continue;
    const amount = tx.amountConverted || tx.amount || 0;
    // In Plaid: positive = expense, negative = income (reversed)
    // Our system normalizes: positive amount = income
    months[monthKey] = (months[monthKey] || 0) + amount;
  }
  return months;
}

/**
 * Clamps a value to 0–100.
 *
 * @param {number} value
 * @returns {number}
 */
function clamp(value) {
  return Math.max(0, Math.min(100, Math.round(value)));
}

module.exports = {
  calculateHealthScore,
  scoreSubscriptionEfficiency,
  scoreSpendingStability,
  scoreSavingsOpportunities,
  scoreCashflowBalance,
  scoreBehavior,
  classifyStatus,
  FACTOR_WEIGHTS,
};
