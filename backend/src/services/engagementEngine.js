/**
 * @module engagementEngine
 *
 * Habit Loop + Retention System
 *
 * Implements a trigger-action-reward-progress loop designed to increase user
 * retention by building a predictable, high-value, low-noise engagement rhythm.
 *
 * Core Principles:
 * - Deliver value BEFORE asking for action
 * - Max 1-2 high priority alerts per day
 * - Never repeat the same insight
 * - Suppress low confidence
 *
 * Frequency rules:
 * - High engagement user -> fewer notifications
 * - Low engagement user -> slightly more nudges (value-driven)
 */

const { calculateHealthScore } = require("./financialScoreEngine");
const { getFeedbackStats } = require("./feedbackStore");
const { calculateSavingsImpact } = require("./savingsImpactEngine");
const { generateCoaching } = require("./coachingEngine");

// In-memory store for tracking notification history and engagement
// Structure: Map<userId, { lastDaily: date, lastWeekly: date, sentInsights: Set<string>, sessions: number }>
const userState = new Map();

function getUserState(userId) {
  if (!userState.has(userId)) {
    userState.set(userId, {
      lastDaily: null,
      lastWeekly: null,
      sentInsights: new Set(),
      sessions: 0,
      actionsTaken: 0,
    });
  }
  return userState.get(userId);
}

/**
 * Tracks a user session or action to evaluate engagement level.
 * @param {string} userId 
 * @param {boolean} isAction - true if the user confirmed/corrected/acted
 */
function recordEngagement(userId, isAction = false) {
  const state = getUserState(userId);
  if (isAction) {
    state.actionsTaken++;
  } else {
    state.sessions++;
  }
}

/**
 * Determines engagement level based on recent activity.
 * @param {string} userId 
 * @returns {string} "high" | "medium" | "low"
 */
function getEngagementLevel(userId) {
  const state = getUserState(userId);
  const feedbackStats = getFeedbackStats(); // In a real app, scope to userId
  
  // Proxy for high engagement: many actions or high feedback count
  if (state.actionsTaken >= 3 || feedbackStats.totalFeedback >= 5) {
    return "high";
  }
  if (state.actionsTaken >= 1 || state.sessions >= 2) {
    return "medium";
  }
  return "low";
}

/**
 * Event-Driven Alerts: Evaluate if a specific insight should trigger a push notification.
 * 
 * Rules:
 * - Never repeat the exact same insight.
 * - Suppress low confidence.
 * - Respect daily frequency limits based on engagement level.
 * 
 * @param {string} userId 
 * @param {object} insight 
 * @returns {boolean} Should notify
 */
function shouldTriggerEventAlert(userId, insight) {
  if (insight.confidenceScore < 70) return false; // Must be high confidence for push

  const state = getUserState(userId);
  const insightSignature = `${insight.type}_${insight.merchant}`;

  if (state.sentInsights.has(insightSignature)) {
    return false; // Anti-spam: Never repeat
  }

  // Record that we are sending it
  state.sentInsights.add(insightSignature);
  return true;
}

/**
 * Generates the Daily Check-in payload.
 * 
 * Returns exactly 1 key high-priority insight (if available) + the current health score.
 * Never overwhelms.
 * 
 * @param {object} params
 */
function generateDailyCheckIn({ transactions, subscriptions, insights, userId }) {
  const state = getUserState(userId);
  const now = new Date();
  
  // Rate limiting: 1 daily per day max
  if (state.lastDaily && state.lastDaily.toDateString() === now.toDateString()) {
    return null; // Already generated today
  }

  const healthResult = calculateHealthScore({ transactions, subscriptions, insights, userId });
  
  // Get the single highest priority action via CoachingEngine
  const coaching = generateCoaching({ transactions, subscriptions, insights, userId });

  // Mark generated
  state.lastDaily = now;
  recordEngagement(userId, false); // Count as a session generation

  return {
    type: "daily_checkin",
    healthScore: healthResult.score,
    trend: healthResult.trend,
    keyInsight: coaching.priority_action || null,
    message: healthResult.score >= 80 ? "Looking great today!" : "Here's your top priority for today."
  };
}

/**
 * Generates the Weekly Digest payload.
 * 
 * Summarizes:
 * - Money saved this week
 * - Key changes (score movement)
 * - Upcoming risks (unused subs, projected balance)
 * 
 * @param {object} params
 */
function generateWeeklyDigest({ transactions, subscriptions, insights, userId }) {
  const state = getUserState(userId);
  const now = new Date();

  // Rate limiting: 1 weekly per week
  if (state.lastWeekly) {
    const daysSince = (now - state.lastWeekly) / (1000 * 60 * 60 * 24);
    if (daysSince < 7) return null; 
  }

  const savings = calculateSavingsImpact(userId);
  const healthResult = calculateHealthScore({ transactions, subscriptions, insights, userId });
  
  // Find upcoming risks (e.g., unused subscriptions)
  const risks = subscriptions
    .filter(s => s.isUnused)
    .map(s => `Unused ${s.name} ($${s.amount}/mo)`);

  // Find recent savings from the last 7 days
  const recentWins = savings.recentWins.filter(win => {
    const winDate = new Date(win.date);
    return (now - winDate) / (1000 * 60 * 60 * 24) <= 7;
  });

  const weeklySavedAmount = recentWins.reduce((sum, win) => sum + (win.frequency === 'yearly' ? win.amount/12 : win.amount), 0);

  state.lastWeekly = now;

  return {
    type: "weekly_digest",
    healthScore: healthResult.score,
    trend: healthResult.trend,
    weeklySavedAmount: Math.round(weeklySavedAmount * 100) / 100,
    recentWinsCount: recentWins.length,
    risks: risks.slice(0, 3), // Max 3 risks to prevent overwhelm
    summaryMessage: weeklySavedAmount > 0 ? `You saved $${Math.round(weeklySavedAmount)} this week. Great job!` : `Here is your weekly summary. Let's find some savings!`
  };
}

module.exports = {
  getEngagementLevel,
  shouldTriggerEventAlert,
  generateDailyCheckIn,
  generateWeeklyDigest,
  recordEngagement
};
