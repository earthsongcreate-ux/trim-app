const savingsImpactEngine = require('./savingsImpactEngine');
const engagementEngine = require('./engagementEngine');

/**
 * Paywall Engine
 * 
 * Maximize conversion by presenting the paywall at high-intent, high-value moments.
 * 
 * PRICING:
 * - Monthly: $12.99
 * - Annual: $99.00
 * - Free Trial: 7 days
 */

// In-memory store for tracking conversions and triggers
// In production, this would be a Postgres table: PaywallEvents
const conversionStore = new Map();

class PaywallEngine {
  constructor() {
    this.PRICING = {
      monthly: 12.99,
      annual: 99.0,
      trialDays: 7
    };
  }

  /**
   * Initializes or gets the paywall state for a user.
   */
  _getUserState(userId) {
    if (!conversionStore.has(userId)) {
      conversionStore.set(userId, {
        isSubscribed: false,
        trialStartDate: new Date().toISOString(),
        firstSavingsSeen: false,
        actionsCompleted: 0,
        appOpens: 0,
        dismissals: 0,
        lastTriggeredAt: null
      });
    }
    return conversionStore.get(userId);
  }

  /**
   * Checks if the user should see the paywall based on Triggers.
   * @param {string} userId
   * @param {string} currentContext - "app_open", "savings_viewed", "action_completed"
   */
  evaluateTrigger(userId, currentContext) {
    const state = this._getUserState(userId);
    
    // If already subscribed, never show paywall
    if (state.isSubscribed) {
      return { showPaywall: false, reason: "already_subscribed" };
    }

    // Trial Expiry Check (HARD PAYWALL)
    const trialStart = new Date(state.trialStartDate);
    const now = new Date();
    const daysSinceStart = (now - trialStart) / (1000 * 60 * 60 * 24);
    
    if (daysSinceStart > this.PRICING.trialDays) {
      return this._generatePaywallPayload(userId, "hard", "trial_expired");
    }

    // Suppress if user dismissed repeatedly (e.g., 3 times) and trial is still active
    if (state.dismissals >= 3) {
      return { showPaywall: false, reason: "suppressed_by_dismissals" };
    }

    // Prevent aggressive repeating (e.g., within 24 hours)
    if (state.lastTriggeredAt) {
      const hoursSinceLast = (now - new Date(state.lastTriggeredAt)) / (1000 * 60 * 60);
      if (hoursSinceLast < 24 && currentContext !== "action_completed") {
        return { showPaywall: false, reason: "rate_limited" };
      }
    }

    // Trigger logic
    let shouldTrigger = false;
    let triggerReason = "";

    if (currentContext === "savings_viewed" && !state.firstSavingsSeen) {
      // 1. FIRST SAVINGS MOMENT (HIGH PRIORITY)
      const impact = savingsImpactEngine.calculateSavingsImpact(userId);
      if (impact.total_saved > 0) {
        state.firstSavingsSeen = true;
        shouldTrigger = true;
        triggerReason = "first_savings_moment";
      }
    } else if (currentContext === "action_completed") {
      // 2. ACTION COMPLETION
      state.actionsCompleted += 1;
      shouldTrigger = true;
      triggerReason = "action_completed";
    } else if (currentContext === "app_open") {
      // 3. ENGAGEMENT TRIGGER
      state.appOpens += 1;
      if (state.appOpens >= 2 && state.appOpens <= 3) {
        shouldTrigger = true;
        triggerReason = "engagement_trigger";
      }
    }

    if (shouldTrigger) {
      state.lastTriggeredAt = now.toISOString();
      return this._generatePaywallPayload(userId, "soft", triggerReason);
    }

    return { showPaywall: false, reason: "no_trigger_met" };
  }

  /**
   * Generates the personalized paywall payload.
   */
  _generatePaywallPayload(userId, type, triggerReason) {
    const impact = savingsImpactEngine.calculateSavingsImpact(userId);
    const totalSaved = impact.total_saved;

    let headline = "Keep optimizing your finances automatically";
    if (totalSaved > 0) {
      headline = `Trim already saved you $${totalSaved.toFixed(0)}`;
    }

    return {
      showPaywall: true,
      paywall: {
        type: type, // "soft" (dismissible) | "hard" (required)
        triggerReason: triggerReason,
        content: {
          headline: headline,
          subtext: "Keep optimizing your finances automatically",
          pricing: {
            monthly: this.PRICING.monthly,
            annual: this.PRICING.annual,
            trialDays: this.PRICING.trialDays
          },
          primaryCta: "Start 7-day free trial",
          secondaryCta: type === "soft" ? "Maybe later" : null
        }
      }
    };
  }

  /**
   * Tracks user interaction with the paywall.
   */
  recordInteraction(userId, action) {
    const state = this._getUserState(userId);
    if (action === "dismiss") {
      state.dismissals += 1;
    } else if (action === "convert") {
      state.isSubscribed = true;
    }
    conversionStore.set(userId, state);
    return state;
  }
}

module.exports = new PaywallEngine();
