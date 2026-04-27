/**
 * Insights Routes — Thin Controller Layer
 *
 * Handles HTTP request/response for financial insight generation.
 * All business logic delegated to insightConfidenceEngine and transactionStore.
 *
 * Endpoints:
 *   GET  /api/insights              — Get scored, filtered insights
 *   GET  /api/insights/all          — Get all insights (including suppressed)
 *   GET  /api/insights/debug/:id    — Get full scoring breakdown for an insight
 */

const express = require("express");
const router = express.Router();
const {
  generateInsights,
  filterForUser,
} = require("../services/insightConfidenceEngine");
const { getAllTransactions } = require("../services/transactionStore");

/**
 * GET /api/insights
 *
 * Returns all user-visible insights (confidence >= medium).
 * Insights are scored, filtered, and tone-adjusted.
 *
 * Response: {
 *   success, insights: [...], count,
 *   suppressed: number (count of hidden low-confidence insights)
 * }
 */
router.get("/", async (req, res) => {
  try {
    const transactions = getAllTransactions();
    const allInsights = generateInsights(transactions);
    const visibleInsights = filterForUser(allInsights);
    const suppressedCount = allInsights.length - visibleInsights.length;

    // Format for client consumption
    const clientInsights = visibleInsights.map(formatInsightForClient);

    res.json({
      success: true,
      insights: clientInsights,
      count: clientInsights.length,
      suppressed: suppressedCount,
    });
  } catch (error) {
    console.error("[Insights] Generation failed:", error.message);
    res.status(500).json({
      success: false,
      error: "Failed to generate insights",
    });
  }
});

/**
 * GET /api/insights/all
 *
 * Returns ALL insights including suppressed low-confidence ones.
 * Used for debugging and admin review.
 *
 * Response: { success, insights: [...], count }
 */
router.get("/all", async (req, res) => {
  try {
    const transactions = getAllTransactions();
    const allInsights = generateInsights(transactions);

    res.json({
      success: true,
      insights: allInsights,
      count: allInsights.length,
    });
  } catch (error) {
    console.error("[Insights] Full fetch failed:", error.message);
    res.status(500).json({
      success: false,
      error: "Failed to generate insights",
    });
  }
});

/**
 * Formats a processed insight for client consumption.
 * Maps internal fields to the iOS FinancialInsight model.
 *
 * @param {object} insight - Processed insight from confidence engine
 * @returns {object} Client-ready insight
 */
function formatInsightForClient(insight) {
  return {
    id: insight.id,
    type: insight.type,
    title: insight.title,
    description: insight.message || insight.description,
    monthlyImpact: insight.monthlyImpact || 0,
    annualImpact: insight.annualImpact || 0,
    primaryAction: insight.primaryAction || "review",
    confidence: insight.confidence,
    confidenceScore: insight.confidenceScore,
    reasoning: insight.reasoning || null,
    showToUser: insight.showToUser,
    merchant: insight.merchant || insight.merchantName || null,
  };
}

module.exports = router;
