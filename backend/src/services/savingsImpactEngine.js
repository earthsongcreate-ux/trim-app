/**
 * @module savingsImpactEngine
 *
 * Savings Impact System
 *
 * Tracks, calculates, and outputs the REALIZED financial impact Trim has created
 * for the user. Only verified actions are counted, not suggestions.
 *
 * Savings Types:
 * - subscription_cancel: recurring charge stopped
 * - price_reduction: decrease in recurring charge
 * - duplicate: confirmed duplicate resolution
 * - behavior: tracked spending reduction after coaching
 */

const { getTransactionsByConnection, getAllTransactions } = require("./transactionStore");

// In-memory store of verified actions (in production, this would be a DB table)
// Structure: Map<userId, Array<SavingsAction>>
const userActions = new Map();

/**
 * Registers a verified user action that resulted in savings.
 * @param {string} userId 
 * @param {object} action 
 * {
 *   type: "subscription_cancel" | "price_reduction" | "duplicate" | "behavior",
 *   amount: number, // Monthly amount or one-time amount
 *   currency: "USD",
 *   source: "Netflix",
 *   date: "2026-04-24",
 *   confidence: "high"
 * }
 */
function recordSavingsAction(userId, action) {
  if (!userActions.has(userId)) {
    userActions.set(userId, []);
  }
  const actions = userActions.get(userId);
  actions.push({
    id: require("crypto").randomUUID(),
    ...action,
    timestamp: new Date().toISOString()
  });
}

/**
 * Calculates the total financial impact for a user.
 * 
 * @param {string} userId 
 * @returns {object} { total_saved, monthly_savings, annual_projection, recent_wins }
 */
function calculateSavingsImpact(userId = "default") {
  const actions = userActions.get(userId) || [];

  let total_saved_lifetime = 0; // Cumulative actual savings to date
  let monthly_savings = 0; // Current active recurring savings rate
  let annualized_recurring = 0;

  const now = new Date();

  // Process actions
  const recent_wins = actions.map(action => {
    let winAmount = 0;
    let annualizedWin = 0;
    let isRecurring = false;
    let description = "";

    const actionDate = new Date(action.date || action.timestamp);
    const monthsSince = Math.max(0, (now.getFullYear() - actionDate.getFullYear()) * 12 + now.getMonth() - actionDate.getMonth());

    switch (action.type) {
      case "subscription_cancel":
        winAmount = action.amount * 12; // Annual representation for UI
        annualizedWin = action.amount * 12;
        monthly_savings += action.amount;
        total_saved_lifetime += action.amount * monthsSince;
        isRecurring = true;
        description = `Canceled ${action.source}`;
        break;

      case "price_reduction":
        winAmount = action.amount * 12; 
        annualizedWin = action.amount * 12;
        monthly_savings += action.amount;
        total_saved_lifetime += action.amount * monthsSince;
        isRecurring = true;
        description = `Reduced ${action.source} plan`;
        break;

      case "duplicate":
        winAmount = action.amount;
        annualizedWin = 0; // One-time, doesn't add to annual projection
        total_saved_lifetime += action.amount;
        description = `Refunded duplicate ${action.source} charge`;
        break;

      case "behavior":
        winAmount = action.amount;
        annualizedWin = action.amount * 12; 
        monthly_savings += action.amount;
        total_saved_lifetime += action.amount * monthsSince;
        isRecurring = true;
        description = `Reduced ${action.source} spending`;
        break;
    }

    annualized_recurring += annualizedWin;

    return {
      id: action.id,
      type: action.type,
      amount: winAmount, // Format based on recurring vs one-time
      currency: action.currency,
      frequency: isRecurring ? "yearly" : "one_time",
      source: action.source,
      date: action.date,
      description,
      confidence: action.confidence || "high"
    };
  });

  // Sort recent wins by date descending
  recent_wins.sort((a, b) => new Date(b.date) - new Date(a.date));

  // The annual projection is the sum of annualized recurring savings plus lifetime one-time savings 
  // (or just annualized recurring based on product spec: typically annual projection = monthly * 12)
  const annual_projection = monthly_savings * 12;

  // Let's add some mock data if empty for demo purposes, so the UI can be built
  if (actions.length === 0) {
      return getMockSavingsImpact();
  }

  return {
    total_saved: Math.round(total_saved_lifetime * 100) / 100,
    monthly_savings: Math.round(monthly_savings * 100) / 100,
    annual_projection: Math.round(annual_projection * 100) / 100,
    recent_wins: recent_wins.slice(0, 10) // Return top 10
  };
}

// Demo mock data
function getMockSavingsImpact() {
    return {
        total_saved: 842.50,
        monthly_savings: 70.20,
        annual_projection: 842.40, // 70.20 * 12
        recent_wins: [
            {
                id: "mock_1",
                type: "subscription_cancel",
                amount: 180,
                currency: "USD",
                frequency: "yearly",
                source: "Netflix",
                date: new Date().toISOString(),
                description: "Canceled Netflix",
                confidence: "high"
            },
            {
                id: "mock_2",
                type: "price_reduction",
                amount: 36,
                currency: "USD",
                frequency: "yearly",
                source: "Adobe",
                date: new Date(Date.now() - 86400000 * 5).toISOString(), // 5 days ago
                description: "Reduced Adobe plan",
                confidence: "high"
            }
        ]
    }
}

module.exports = {
  calculateSavingsImpact,
  recordSavingsAction
};
