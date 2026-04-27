/**
 * Coaching Routes — Thin Controller Layer
 *
 * Handles HTTP request/response for the Behavioral Finance Coaching Engine.
 *
 * Endpoints:
 *   GET  /api/coaching          — Get personalized coaching actions
 */

const express = require("express");
const router = express.Router();
const { generateCoaching } = require("../services/coachingEngine");
const { getAllTransactions } = require("../services/transactionStore");
const { generateInsights } = require("../services/insightConfidenceEngine");

/**
 * GET /api/coaching
 *
 * Computes and returns personalized coaching actions for the user.
 *
 * Query params:
 *   ?userId=<string> — User ID for personalized behavior tracking
 *
 * Response: {
 *   success: true,
 *   coaching: {
 *     priority_action: { title, description, impact, confidence, type },
 *     secondary_actions: [ ... ]
 *   }
 * }
 */
router.get("/", async (req, res) => {
  try {
    const userId = req.query.userId || "default";
    const transactions = getAllTransactions();
    
    // We need subscriptions and insights
    const allInsights = generateInsights(transactions);
    const subscriptions = extractSubscriptions(transactions);

    const coaching = generateCoaching({
      transactions,
      subscriptions,
      insights: allInsights,
      userId,
    });

    res.json({
      success: true,
      coaching,
    });
  } catch (error) {
    console.error("[Coaching] Generation failed:", error.message);
    res.status(500).json({
      success: false,
      error: "Failed to generate coaching",
    });
  }
});

/**
 * Derives subscription-like records from recurring transactions.
 * (Duplicated from healthScore.js for modularity, can be extracted to a shared util later)
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
        isUnused: false, 
        charges: [],
      });
    }

    const sub = recurringMerchants.get(key);
    sub.charges.push(tx);
    if (tx.date > sub.lastBilled) {
      sub.lastBilled = tx.date;
    }
  }

  return Array.from(recurringMerchants.values());
}

module.exports = router;
