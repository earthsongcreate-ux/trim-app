/**
 * @module feedbackStore
 *
 * User Feedback Loop — Storage & Learning System
 *
 * Captures, stores, and learns from user feedback on financial insights
 * and transaction normalization to continuously improve system accuracy.
 *
 * Architecture:
 * 1. Feedback Capture — stores raw user feedback (confirm / correct)
 * 2. User Override Layer — per-user corrections that override global logic
 * 3. Global Learning — when multiple users agree, updates global dictionary
 * 4. Confidence Adjustment — feeds scores back into InsightConfidenceEngine
 *
 * Storage (current): In-memory (development/prototype)
 * Production: Replace with PostgreSQL / Redis
 *
 * Learning thresholds:
 * - Global merchant update: 3+ unique users correct the same mapping
 * - Global category update: 5+ unique users correct the same category
 * - Confidence boost:  +10 per confirmation (capped at 100)
 * - Confidence penalty: -15 per correction (floored at 0)
 */

// MARK: — In-Memory Stores

/**
 * All feedback entries, keyed by feedbackId.
 * @type {Map<string, object>}
 */
const feedbackEntries = new Map();

/**
 * User-specific overrides.
 * Structure: Map<userId, Map<merchantRaw, { merchant, category, isRecurring }>>
 * @type {Map<string, Map<string, object>>}
 */
const userOverrides = new Map();

/**
 * Global correction aggregator.
 * Tracks how many unique users have made the same correction.
 * Structure: Map<correctionKey, { correction, userIds: Set<string>, count }>
 * @type {Map<string, object>}
 */
const globalCorrections = new Map();

/**
 * Confidence adjustments from feedback.
 * Structure: Map<merchantName, { boosts: number, penalties: number, net: number }>
 * @type {Map<string, object>}
 */
const confidenceAdjustments = new Map();

// MARK: — Thresholds

const LEARNING_THRESHOLDS = {
  globalMerchantUpdate: 3,
  globalCategoryUpdate: 5,
  confidenceBoostPerConfirm: 10,
  confidencePenaltyPerCorrect: 15,
  maxConfidence: 100,
  minConfidence: 0,
};

// MARK: — Public API: Feedback Capture

/**
 * Records a user's feedback on an insight or transaction.
 *
 * @param {object} params
 * @param {string} params.userId - User identifier
 * @param {string} params.targetId - Insight or transaction ID
 * @param {string} params.targetType - "insight" or "transaction"
 * @param {string} params.feedbackType - "confirm" or "correct"
 * @param {object} params.originalPrediction - System's original output
 * @param {object|null} params.userCorrection - User's correction (if feedbackType === "correct")
 * @returns {object} Stored feedback entry with applied learning results
 */
function submitFeedback({
  userId,
  targetId,
  targetType = "insight",
  feedbackType,
  originalPrediction = {},
  userCorrection = null,
}) {
  if (!userId || !targetId || !feedbackType) {
    throw new Error("userId, targetId, and feedbackType are required");
  }

  if (!["confirm", "correct"].includes(feedbackType)) {
    throw new Error('feedbackType must be "confirm" or "correct"');
  }

  const feedbackId = generateFeedbackId();
  const timestamp = new Date().toISOString();

  const entry = {
    feedbackId,
    userId,
    targetId,
    targetType,
    feedbackType,
    originalPrediction: {
      merchant: originalPrediction.merchant || null,
      category: originalPrediction.category || null,
      isRecurring: originalPrediction.isRecurring ?? null,
    },
    userCorrection: userCorrection
      ? {
          merchant: userCorrection.merchant || null,
          category: userCorrection.category || null,
          isRecurring: userCorrection.isRecurring ?? null,
        }
      : null,
    timestamp,
    learningApplied: false,
  };

  // Store the feedback
  feedbackEntries.set(feedbackId, entry);

  // Apply learning
  const learningResult = applyLearning(entry);
  entry.learningApplied = learningResult.applied;
  entry.learningDetails = learningResult;

  return entry;
}

/**
 * Retrieves all feedback for a specific user.
 *
 * @param {string} userId
 * @returns {Array<object>}
 */
function getUserFeedback(userId) {
  const results = [];
  for (const entry of feedbackEntries.values()) {
    if (entry.userId === userId) {
      results.push(entry);
    }
  }
  return results.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
}

/**
 * Retrieves feedback stats for monitoring.
 *
 * @returns {object}
 */
function getFeedbackStats() {
  let confirms = 0;
  let corrections = 0;
  const uniqueUsers = new Set();

  for (const entry of feedbackEntries.values()) {
    uniqueUsers.add(entry.userId);
    if (entry.feedbackType === "confirm") confirms++;
    else corrections++;
  }

  return {
    totalFeedback: feedbackEntries.size,
    confirms,
    corrections,
    accuracy: feedbackEntries.size > 0
      ? Math.round((confirms / feedbackEntries.size) * 100)
      : 100,
    uniqueUsers: uniqueUsers.size,
    globalCorrectionsApplied: countAppliedGlobalCorrections(),
    userOverridesActive: countActiveUserOverrides(),
  };
}

// MARK: — Learning System

/**
 * Applies learning from a feedback entry.
 *
 * For confirmations:
 * - Boosts confidence for the merchant/insight
 *
 * For corrections:
 * - Stores user-specific override
 * - Aggregates into global corrections
 * - If threshold met, promotes to global dictionary update
 * - Penalizes confidence for the original prediction
 *
 * @param {object} entry - Feedback entry
 * @returns {object} Learning result
 */
function applyLearning(entry) {
  const result = {
    applied: false,
    userOverrideSet: false,
    globalCorrectionTracked: false,
    globalUpdateApplied: false,
    confidenceAdjusted: false,
  };

  const merchantKey =
    entry.originalPrediction.merchant ||
    entry.targetId;

  if (entry.feedbackType === "confirm") {
    // Boost confidence
    adjustConfidence(merchantKey, "boost");
    result.applied = true;
    result.confidenceAdjusted = true;
    return result;
  }

  // feedbackType === "correct"
  if (!entry.userCorrection) return result;

  // 1. Set user-specific override
  setUserOverride(entry.userId, merchantKey, entry.userCorrection);
  result.userOverrideSet = true;
  result.applied = true;

  // 2. Penalize confidence for original prediction
  adjustConfidence(merchantKey, "penalty");
  result.confidenceAdjusted = true;

  // 3. Track global correction
  const correctionKey = buildCorrectionKey(entry);
  trackGlobalCorrection(correctionKey, entry.userId, entry.userCorrection);
  result.globalCorrectionTracked = true;

  // 4. Check if global threshold is met
  const globalEntry = globalCorrections.get(correctionKey);
  if (globalEntry) {
    const threshold = entry.userCorrection.merchant
      ? LEARNING_THRESHOLDS.globalMerchantUpdate
      : LEARNING_THRESHOLDS.globalCategoryUpdate;

    if (globalEntry.count >= threshold && !globalEntry.applied) {
      globalEntry.applied = true;
      result.globalUpdateApplied = true;
      // The actual dictionary update is handled by the integration layer
      // when it queries getPromotedCorrections()
    }
  }

  return result;
}

// MARK: — User Overrides

/**
 * Sets a user-specific override for a merchant.
 *
 * @param {string} userId
 * @param {string} merchantKey - Raw or canonical merchant name
 * @param {object} correction - { merchant, category, isRecurring }
 */
function setUserOverride(userId, merchantKey, correction) {
  if (!userOverrides.has(userId)) {
    userOverrides.set(userId, new Map());
  }

  const userMap = userOverrides.get(userId);
  userMap.set(merchantKey.toLowerCase(), {
    ...correction,
    updatedAt: new Date().toISOString(),
  });
}

/**
 * Gets a user's override for a specific merchant.
 * Used by the normalization pipeline to check for user-specific corrections.
 *
 * @param {string} userId
 * @param {string} merchantName - Merchant name to check (raw or canonical)
 * @returns {object|null} Override correction or null
 */
function getUserOverride(userId, merchantName) {
  if (!userId || !merchantName) return null;

  const userMap = userOverrides.get(userId);
  if (!userMap) return null;

  return userMap.get(merchantName.toLowerCase()) || null;
}

/**
 * Gets all overrides for a user.
 *
 * @param {string} userId
 * @returns {Array<object>}
 */
function getAllUserOverrides(userId) {
  const userMap = userOverrides.get(userId);
  if (!userMap) return [];

  const results = [];
  for (const [key, value] of userMap.entries()) {
    results.push({ merchantKey: key, ...value });
  }
  return results;
}

// MARK: — Global Corrections

/**
 * Tracks a global correction from a user.
 *
 * @param {string} correctionKey
 * @param {string} userId
 * @param {object} correction
 */
function trackGlobalCorrection(correctionKey, userId, correction) {
  if (!globalCorrections.has(correctionKey)) {
    globalCorrections.set(correctionKey, {
      correction,
      userIds: new Set(),
      count: 0,
      applied: false,
      createdAt: new Date().toISOString(),
    });
  }

  const entry = globalCorrections.get(correctionKey);

  // Only count unique users
  if (!entry.userIds.has(userId)) {
    entry.userIds.add(userId);
    entry.count = entry.userIds.size;
  }
}

/**
 * Returns global corrections that have met the threshold
 * and are ready to be promoted to the dictionary.
 *
 * @returns {Array<object>}
 */
function getPromotedCorrections() {
  const promoted = [];

  for (const [key, entry] of globalCorrections.entries()) {
    if (entry.applied) {
      promoted.push({
        correctionKey: key,
        correction: entry.correction,
        agreedBy: entry.count,
        createdAt: entry.createdAt,
      });
    }
  }

  return promoted;
}

// MARK: — Confidence Adjustments

/**
 * Adjusts confidence score for a merchant based on feedback.
 *
 * @param {string} merchantKey
 * @param {string} direction - "boost" or "penalty"
 */
function adjustConfidence(merchantKey, direction) {
  const key = merchantKey.toLowerCase();

  if (!confidenceAdjustments.has(key)) {
    confidenceAdjustments.set(key, { boosts: 0, penalties: 0, net: 0 });
  }

  const adj = confidenceAdjustments.get(key);

  if (direction === "boost") {
    adj.boosts++;
    adj.net = Math.min(
      LEARNING_THRESHOLDS.maxConfidence,
      adj.net + LEARNING_THRESHOLDS.confidenceBoostPerConfirm
    );
  } else {
    adj.penalties++;
    adj.net = Math.max(
      -LEARNING_THRESHOLDS.maxConfidence,
      adj.net - LEARNING_THRESHOLDS.confidencePenaltyPerCorrect
    );
  }
}

/**
 * Gets the confidence adjustment for a merchant.
 * Used by the InsightConfidenceEngine to modify scores.
 *
 * @param {string} merchantName
 * @returns {number} Net adjustment (-100 to +100)
 */
function getConfidenceAdjustment(merchantName) {
  if (!merchantName) return 0;

  const adj = confidenceAdjustments.get(merchantName.toLowerCase());
  return adj ? adj.net : 0;
}

/**
 * Gets all confidence adjustments (for debugging).
 *
 * @returns {Array<object>}
 */
function getAllConfidenceAdjustments() {
  const results = [];
  for (const [key, value] of confidenceAdjustments.entries()) {
    results.push({ merchant: key, ...value });
  }
  return results;
}

// MARK: — Helpers

/**
 * Builds a unique key for a correction to aggregate across users.
 *
 * @param {object} entry - Feedback entry
 * @returns {string}
 */
function buildCorrectionKey(entry) {
  const parts = [];

  if (entry.originalPrediction.merchant) {
    parts.push(`from:${entry.originalPrediction.merchant.toLowerCase()}`);
  }
  if (entry.userCorrection?.merchant) {
    parts.push(`to_merchant:${entry.userCorrection.merchant.toLowerCase()}`);
  }
  if (entry.userCorrection?.category) {
    parts.push(`to_category:${entry.userCorrection.category.toLowerCase()}`);
  }
  if (entry.userCorrection?.isRecurring !== null && entry.userCorrection?.isRecurring !== undefined) {
    parts.push(`to_recurring:${entry.userCorrection.isRecurring}`);
  }

  return parts.join("|");
}

/**
 * Counts global corrections that have been applied.
 *
 * @returns {number}
 */
function countAppliedGlobalCorrections() {
  let count = 0;
  for (const entry of globalCorrections.values()) {
    if (entry.applied) count++;
  }
  return count;
}

/**
 * Counts total active user overrides across all users.
 *
 * @returns {number}
 */
function countActiveUserOverrides() {
  let count = 0;
  for (const userMap of userOverrides.values()) {
    count += userMap.size;
  }
  return count;
}

/**
 * Generates a unique feedback ID.
 *
 * @returns {string}
 */
function generateFeedbackId() {
  return `fb_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`;
}

module.exports = {
  // Feedback capture
  submitFeedback,
  getUserFeedback,
  getFeedbackStats,

  // User overrides (consumed by normalization pipeline)
  getUserOverride,
  getAllUserOverrides,

  // Global learning (consumed by merchant mapping)
  getPromotedCorrections,

  // Confidence adjustments (consumed by insight confidence engine)
  getConfidenceAdjustment,
  getAllConfidenceAdjustments,

  // Constants
  LEARNING_THRESHOLDS,
};
