/**
 * Feedback Routes — Thin Controller Layer
 *
 * Handles HTTP request/response for the user feedback loop.
 * All business logic delegated to feedbackStore.
 *
 * Endpoints:
 *   POST /api/feedback                — Submit feedback (confirm/correct)
 *   GET  /api/feedback/:userId        — Get user's feedback history
 *   GET  /api/feedback/stats          — Get system-wide feedback stats
 *   GET  /api/feedback/overrides/:userId — Get user-specific overrides
 *   GET  /api/feedback/promoted       — Get globally promoted corrections
 */

const express = require("express");
const router = express.Router();
const {
  submitFeedback,
  getUserFeedback,
  getFeedbackStats,
  getAllUserOverrides,
  getPromotedCorrections,
} = require("../services/feedbackStore");
const { getCategories } = require("../services/categoryClassificationEngine");

/**
 * POST /api/feedback
 *
 * Submits user feedback on an insight or transaction.
 * One-tap submission: feedbackType "confirm" or "correct".
 *
 * Body: {
 *   userId:             string  (required)
 *   targetId:           string  (required — insight or transaction ID)
 *   targetType:         string  ("insight" | "transaction")
 *   feedbackType:       string  ("confirm" | "correct")
 *   originalPrediction: { merchant, category, isRecurring }
 *   userCorrection:     { merchant, category, isRecurring } (if feedbackType === "correct")
 * }
 *
 * Response: { success, feedback: {...}, learning: {...} }
 */
router.post("/", async (req, res) => {
  try {
    const {
      userId,
      targetId,
      targetType,
      feedbackType,
      originalPrediction,
      userCorrection,
    } = req.body;

    // Validate required fields
    if (!userId || !targetId || !feedbackType) {
      return res.status(400).json({
        success: false,
        error: "userId, targetId, and feedbackType are required",
      });
    }

    if (!["confirm", "correct"].includes(feedbackType)) {
      return res.status(400).json({
        success: false,
        error: 'feedbackType must be "confirm" or "correct"',
      });
    }

    // If correcting, validate at least one correction field is present
    if (feedbackType === "correct") {
      if (
        !userCorrection ||
        (!userCorrection.merchant &&
          !userCorrection.category &&
          userCorrection.isRecurring === undefined)
      ) {
        return res.status(400).json({
          success: false,
          error: "At least one correction field is required (merchant, category, or isRecurring)",
        });
      }

      // Validate category if provided
      if (userCorrection.category) {
        const validCategories = getCategories();
        if (!validCategories.includes(userCorrection.category)) {
          return res.status(400).json({
            success: false,
            error: `Invalid category. Valid options: ${validCategories.join(", ")}`,
          });
        }
      }
    }

    const result = submitFeedback({
      userId,
      targetId,
      targetType: targetType || "insight",
      feedbackType,
      originalPrediction: originalPrediction || {},
      userCorrection: feedbackType === "correct" ? userCorrection : null,
    });

    res.json({
      success: true,
      feedback: {
        feedbackId: result.feedbackId,
        feedbackType: result.feedbackType,
        timestamp: result.timestamp,
      },
      learning: result.learningDetails || null,
    });
  } catch (error) {
    console.error("[Feedback] Submit failed:", error.message);
    res.status(500).json({
      success: false,
      error: "Failed to submit feedback",
    });
  }
});

/**
 * GET /api/feedback/stats
 *
 * Returns system-wide feedback statistics.
 * Used for monitoring system accuracy improvements.
 *
 * Response: { success, stats: { totalFeedback, confirms, corrections, accuracy, ... } }
 */
router.get("/stats", async (req, res) => {
  try {
    const stats = getFeedbackStats();
    res.json({
      success: true,
      stats,
    });
  } catch (error) {
    console.error("[Feedback] Stats fetch failed:", error.message);
    res.status(500).json({
      success: false,
      error: "Failed to retrieve feedback stats",
    });
  }
});

/**
 * GET /api/feedback/promoted
 *
 * Returns corrections that have been promoted to global updates.
 * When enough users agree on a correction, it becomes a global rule.
 *
 * Response: { success, corrections: [...], count }
 */
router.get("/promoted", async (req, res) => {
  try {
    const corrections = getPromotedCorrections();
    res.json({
      success: true,
      corrections,
      count: corrections.length,
    });
  } catch (error) {
    console.error("[Feedback] Promoted fetch failed:", error.message);
    res.status(500).json({
      success: false,
      error: "Failed to retrieve promoted corrections",
    });
  }
});

/**
 * GET /api/feedback/overrides/:userId
 *
 * Returns user-specific overrides for a given user.
 *
 * Response: { success, overrides: [...], count }
 */
router.get("/overrides/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const overrides = getAllUserOverrides(userId);

    res.json({
      success: true,
      overrides,
      count: overrides.length,
    });
  } catch (error) {
    console.error("[Feedback] Overrides fetch failed:", error.message);
    res.status(500).json({
      success: false,
      error: "Failed to retrieve user overrides",
    });
  }
});

/**
 * GET /api/feedback/:userId
 *
 * Returns feedback history for a specific user.
 *
 * Response: { success, feedback: [...], count }
 */
router.get("/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const feedback = getUserFeedback(userId);

    res.json({
      success: true,
      feedback,
      count: feedback.length,
    });
  } catch (error) {
    console.error("[Feedback] History fetch failed:", error.message);
    res.status(500).json({
      success: false,
      error: "Failed to retrieve feedback history",
    });
  }
});

module.exports = router;
