/**
 * Health Score Routes — Thin Controller Layer
 *
 * Handles HTTP request/response for the Financial Health Score.
 * All business logic delegated to financialScoreEngine.
 *
 * Endpoints:
 *   GET  /api/health-score          — Get computed health score
 *   GET  /api/health-score/factors  — Get individual factor breakdown
 */

const express = require("express");
const router = express.Router();
const { calculateHealthScore } = require("../services/financialScoreEngine");
const { getAllTransactions } = require("../services/transactionStore");
const {
  generateInsights,
} = require("../services/insightConfidenceEngine");

/**
 * GET /api/health-score
 *
 * Computes and returns the user's financial health score.
 * Accepts optional userId query parameter for personalized scoring.
 *
 * Query params:
 *   ?userId=<string> — User ID for behavior scoring and trend tracking
 *
 * Response: {
 *   success,
 *   score: 78,
 *   status: "Good",
 *   factors: { subscriptions, spending, savings, cashflow, behavior },
 *   trend: "up" | "down" | "stable",
 *   computedAt: ISO string
 * }
 */
router.get("/", async (req, res) => {
  try {
    const userId = req.query.userId || "default";
    const transactions = getAllTransactions();

    // Generate all insights (including suppressed) for scoring
    const allInsights = generateInsights(transactions);

    // Extract subscriptions from recurring transactions
    const subscriptions = extractSubscriptions(transactions);

    const result = calculateHealthScore({
      transactions,
      subscriptions,
      insights: allInsights,
      userId,
    });

    res.json({
      success: true,
      ...result,
    });
  } catch (error) {
    console.error("[HealthScore] Computation failed:", error.message);
    res.status(500).json({
      success: false,
      error: "Failed to compute health score",
    });
  }
});

/**
 * GET /api/health-score/factors
 *
 * Returns the detailed breakdown of each scoring factor.
 * Useful for the "How is my score calculated?" detail view.
 *
 * Response: {
 *   success,
 *   factors: { subscriptions, spending, savings, cashflow, behavior },
 *   weights: { subscriptions: 0.25, ... },
 *   descriptions: { subscriptions: "...", ... }
 * }
 */
router.get("/factors", async (req, res) => {
  try {
    const userId = req.query.userId || "default";
    const transactions = getAllTransactions();
    const allInsights = generateInsights(transactions);
    const subscriptions = extractSubscriptions(transactions);

    const result = calculateHealthScore({
      transactions,
      subscriptions,
      insights: allInsights,
      userId,
    });

    res.json({
      success: true,
      factors: result.factors,
      weights: {
        subscriptions: 0.25,
        spending: 0.25,
        savings: 0.20,
        cashflow: 0.20,
        behavior: 0.10,
      },
      descriptions: {
        subscriptions: "Evaluates unused subscriptions, price increases, and duplicate charges.",
        spending: "Measures spending consistency and detects unusual spikes.",
        savings: "Tracks identified savings opportunities and action taken.",
        cashflow: "Analyzes income versus expense balance and trend direction.",
        behavior: "Rewards engagement with insights and feedback system.",
      },
    });
  } catch (error) {
    console.error("[HealthScore] Factors fetch failed:", error.message);
    res.status(500).json({
      success: false,
      error: "Failed to compute factor breakdown",
    });
  }
});

/**
 * Derives subscription-like records from recurring transactions.
 * Bridges the gap between normalized transactions and the score engine's
 * subscription input format.
 *
 * @param {Array<object>} transactions
 * @returns {Array<object>} Subscription-shaped records
 */
function extractSubscriptions(transactions) {
  const recurringMerchants = new Map();

  for (const tx of transactions) {
    if (!tx.isRecurring || tx.category === "income") continue;

    const key = (tx.merchantName || tx.merchantClean || "unknown").toLowerCase();
    if (!recurringMerchants.has(key)) {
      recurringMerchants.set(key, {
        name: tx.merchantName || tx.merchantClean || tx.merchantRaw,
        amount: Math.abs(tx.amountConverted || tx.amount || 0),
        frequency: tx.recurringInterval || "monthly",
        category: tx.category || "other",
        lastBilled: tx.date,
        isUnused: false, // Cannot determine from transactions alone
        charges: [],
      });
    }

    const sub = recurringMerchants.get(key);
    sub.charges.push(tx);

    // Update latest billing date
    if (tx.date > sub.lastBilled) {
      sub.lastBilled = tx.date;
    }
  }

  return Array.from(recurringMerchants.values());
}

module.exports = router;
