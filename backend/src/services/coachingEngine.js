/**
 * @module coachingEngine
 *
 * Behavioral Finance Coaching Engine
 *
 * Guides users toward better financial decisions using personalized, actionable coaching.
 * Focuses on 1-2 high-impact actions at a time to avoid overwhelming the user.
 *
 * Inputs:
 * - Financial Health Score
 * - Insights (subscriptions, duplicates, spending)
 * - User Behavior (feedback loop stats)
 *
 * Coaching Types:
 * 1. Save Money (cancel unused subs, reduce recurring)
 * 2. Stabilize Spending (reduce spikes, flag unusual)
 * 3. Improve Habits (encourage consistency, reward positive actions)
 *
 * Output:
 * {
 *   priority_action: { title, description, impact, confidence, type, actionData },
 *   secondary_actions: [ ... ]
 * }
 */

const { calculateHealthScore } = require("./financialScoreEngine");
const { getFeedbackStats } = require("./feedbackStore");

// MARK: — Coaching Types & Impacts

const COACHING_TYPES = {
  SAVE_MONEY: "save_money",
  STABILIZE_SPENDING: "stabilize_spending",
  IMPROVE_HABITS: "improve_habits",
};

const IMPACT_LEVELS = {
  HIGH: "high",
  MEDIUM: "medium",
  LOW: "low",
};

// MARK: — Public API

/**
 * Generates personalized coaching actions for the user.
 *
 * @param {object} params
 * @param {Array<object>} params.transactions
 * @param {Array<object>} params.subscriptions
 * @param {Array<object>} params.insights - All insights (scored)
 * @param {string} params.userId
 * @returns {object} { priority_action, secondary_actions }
 */
function generateCoaching({ transactions, subscriptions, insights, userId = "default" }) {
  const healthResult = calculateHealthScore({ transactions, subscriptions, insights, userId });
  const feedbackStats = getFeedbackStats();

  const allActions = [];

  // 1. Analyze Savings Opportunities (SAVE_MONEY)
  const savingsActions = generateSavingsCoaching(insights);
  allActions.push(...savingsActions);

  // 2. Analyze Spending Stability (STABILIZE_SPENDING)
  const spendingActions = generateSpendingCoaching(healthResult.factors.spending, insights);
  allActions.push(...spendingActions);

  // 3. Analyze Habits (IMPROVE_HABITS)
  const habitActions = generateHabitCoaching(healthResult, feedbackStats);
  allActions.push(...habitActions);

  // 4. Rank and Filter Actions
  const rankedActions = rankActions(allActions);

  if (rankedActions.length === 0) {
    return {
      priority_action: getDefaultPositiveCoaching(healthResult.score),
      secondary_actions: [],
    };
  }

  return {
    priority_action: rankedActions[0],
    secondary_actions: rankedActions.slice(1, 3), // Keep max 2 secondary actions
  };
}

// MARK: — Action Generators

function generateSavingsCoaching(insights) {
  const actions = [];
  
  // Look for unused subscriptions or price increases
  const subInsights = insights.filter(
    (i) => (i.type === "subscriptionIncrease" || i.type === "savingOpportunity" || i.type === "subscription_increase" || i.type === "saving_opportunity") 
           && i.confidenceScore >= 60
  );

  for (const insight of subInsights) {
    actions.push({
      type: COACHING_TYPES.SAVE_MONEY,
      title: `Review ${insight.merchant || 'Subscription'}`,
      description: insight.description || `You might be able to save money by reviewing this subscription.`,
      impact: (insight.annualImpact || insight.monthlyImpact * 12) > 100 ? IMPACT_LEVELS.HIGH : IMPACT_LEVELS.MEDIUM,
      confidence: "high",
      actionData: { insightId: insight.id, merchant: insight.merchant },
      score: 90 + Math.min(10, (insight.annualImpact || 0) / 10), // Prioritize higher impact
    });
  }

  // Look for duplicates
  const dupInsights = insights.filter(
    (i) => (i.type === "duplicateCharge" || i.type === "duplicate_charge") && i.confidenceScore >= 70
  );

  for (const insight of dupInsights) {
    actions.push({
      type: COACHING_TYPES.SAVE_MONEY,
      title: `Possible Duplicate Charge`,
      description: `We noticed a possible duplicate charge for ${insight.merchant}. Review to get a refund.`,
      impact: IMPACT_LEVELS.HIGH,
      confidence: "high",
      actionData: { insightId: insight.id, merchant: insight.merchant },
      score: 95, // High priority to fix duplicates
    });
  }

  return actions;
}

function generateSpendingCoaching(spendingScore, insights) {
  const actions = [];

  if (spendingScore < 50) {
    actions.push({
      type: COACHING_TYPES.STABILIZE_SPENDING,
      title: "Stabilize Your Spending",
      description: "Your spending has been more volatile recently. Try setting a weekly limit for non-essential purchases.",
      impact: IMPACT_LEVELS.HIGH,
      confidence: "medium",
      actionData: null,
      score: 85 - spendingScore, // Lower score = higher priority
    });
  }

  // Find unusual spending insights
  const unusualInsights = insights.filter(
    (i) => (i.type === "unusualSpending" || i.type === "unusual_spending") && i.confidenceScore >= 60
  );

  for (const insight of unusualInsights) {
    actions.push({
      type: COACHING_TYPES.STABILIZE_SPENDING,
      title: "Unusual Spending Detected",
      description: insight.description || `Your spending at ${insight.merchant} is unusually high.`,
      impact: IMPACT_LEVELS.MEDIUM,
      confidence: "medium",
      actionData: { insightId: insight.id, merchant: insight.merchant },
      score: 75,
    });
  }

  return actions;
}

function generateHabitCoaching(healthResult, feedbackStats) {
  const actions = [];
  const { trend, score } = healthResult;

  if (trend === "up") {
    actions.push({
      type: COACHING_TYPES.IMPROVE_HABITS,
      title: "Great Momentum!",
      description: "Your financial health score is trending up. Keep up the good habits!",
      impact: IMPACT_LEVELS.LOW,
      confidence: "high",
      actionData: null,
      score: 40, // Lower priority than fixing issues
    });
  } else if (trend === "down" && score < 70) {
    actions.push({
      type: COACHING_TYPES.IMPROVE_HABITS,
      title: "Let's Get Back on Track",
      description: "Your score dipped slightly. Review your recent insights to see where you can improve.",
      impact: IMPACT_LEVELS.MEDIUM,
      confidence: "high",
      actionData: null,
      score: 60,
    });
  }

  if (feedbackStats.totalFeedback === 0) {
    actions.push({
      type: COACHING_TYPES.IMPROVE_HABITS,
      title: "Help Us Learn",
      description: "Confirm or correct insights to help Trim personalize your experience.",
      impact: IMPACT_LEVELS.MEDIUM,
      confidence: "high",
      actionData: { type: "feedback_prompt" },
      score: 50,
    });
  }

  return actions;
}

// MARK: — Helpers

function rankActions(actions) {
  // Sort descending by calculated priority score
  return actions.sort((a, b) => b.score - a.score).map((a) => {
    // Remove internal score from output
    const { score, ...cleanAction } = a;
    return cleanAction;
  });
}

function getDefaultPositiveCoaching(healthScore) {
  if (healthScore >= 80) {
    return {
      type: COACHING_TYPES.IMPROVE_HABITS,
      title: "You're Doing Great",
      description: "Your finances look healthy. Keep up the consistent habits.",
      impact: IMPACT_LEVELS.LOW,
      confidence: "high",
      actionData: null,
    };
  } else {
    return {
      type: COACHING_TYPES.IMPROVE_HABITS,
      title: "Steady Progress",
      description: "You're on the right track. We'll let you know if we spot any savings opportunities.",
      impact: IMPACT_LEVELS.LOW,
      confidence: "high",
      actionData: null,
    };
  }
}

module.exports = {
  generateCoaching,
  COACHING_TYPES,
  IMPACT_LEVELS,
};
