/**
 * Savings Impact Routes — Thin Controller Layer
 *
 * Handles HTTP request/response for the Savings Impact System.
 *
 * Endpoints:
 *   GET  /api/savings/impact  — Get overall savings impact
 *   POST /api/savings/action  — Record a new realized saving action
 */

const express = require("express");
const router = express.Router();
const { calculateSavingsImpact, recordSavingsAction } = require("../services/savingsImpactEngine");

/**
 * GET /api/savings/impact
 *
 * Returns the calculated savings impact for the user.
 *
 * Query params:
 *   ?userId=<string> 
 *
 * Response: {
 *   success: true,
 *   total_saved: 842.50,
 *   monthly_savings: 70.20,
 *   annual_projection: 842.50,
 *   recent_wins: [ ... ]
 * }
 */
router.get("/impact", (req, res) => {
  try {
    const userId = req.query.userId || "default";
    const impact = calculateSavingsImpact(userId);

    res.json({
      success: true,
      ...impact,
    });
  } catch (error) {
    console.error("[Savings] Impact fetch failed:", error.message);
    res.status(500).json({
      success: false,
      error: "Failed to fetch savings impact",
    });
  }
});

/**
 * POST /api/savings/action
 *
 * Records a new verified user action that resulted in savings.
 * 
 * Body: {
 *   type: "subscription_cancel" | "price_reduction" | "duplicate" | "behavior",
 *   amount: 15.00,
 *   currency: "USD",
 *   source: "Netflix",
 *   date: "2026-04-24",
 *   confidence: "high"
 * }
 */
router.post("/action", express.json(), (req, res) => {
  try {
    const userId = req.body.userId || "default";
    const { type, amount, currency, source, date, confidence } = req.body;

    if (!type || !amount || !source) {
        return res.status(400).json({ success: false, error: "Missing required fields" });
    }

    recordSavingsAction(userId, { type, amount, currency, source, date: date || new Date().toISOString(), confidence });

    res.json({
      success: true,
      message: "Action recorded successfully"
    });
  } catch (error) {
    console.error("[Savings] Action record failed:", error.message);
    res.status(500).json({
      success: false,
      error: "Failed to record savings action",
    });
  }
});

module.exports = router;
