from typing import Dict, Any

def _calc_waste_control(metrics: Dict[str, Any]) -> float:
    """30% Weight: Penalizes for active unnecessary subscriptions and duplicate charges."""
    unnecessary_subs = metrics.get("active_unnecessary_subs", 0)
    duplicate_charges = metrics.get("duplicate_charges_count", 0)
    
    penalty = (unnecessary_subs * 15) + (duplicate_charges * 20)
    return max(0.0, 100.0 - penalty)

def _calc_savings_impact(metrics: Dict[str, Any]) -> float:
    """25% Weight: Rewards total money saved and monthly growth percentage."""
    total_saved = metrics.get("total_money_saved", 0.0)
    monthly_growth = metrics.get("monthly_savings_growth_pct", 0.0)
    
    points_from_savings = min(50.0, total_saved / 10.0) # E.g., $500 saved = max 50 pts
    points_from_growth = min(50.0, max(0.0, monthly_growth * 2.0))
    
    return points_from_savings + points_from_growth

def _calc_spending_stability(metrics: Dict[str, Any]) -> float:
    """20% Weight: Penalizes irregular spending spikes."""
    irregular_spikes = metrics.get("irregular_spikes_count", 0)
    penalty = irregular_spikes * 15
    return max(0.0, 100.0 - penalty)

def _calc_optimization_actions(metrics: Dict[str, Any]) -> float:
    """15% Weight: Directly rewards taking financial action."""
    actions = metrics.get("cancellations_completed", 0) + metrics.get("negotiations_attempted", 0)
    # Each action grants 20 points, up to 100
    return min(100.0, actions * 20.0)

def _calc_engagement(metrics: Dict[str, Any]) -> float:
    """10% Weight: Rewards app usage and insight review habits."""
    streak = metrics.get("login_streak", 0)
    insights_reviewed = metrics.get("insights_reviewed", 0)
    
    score = min(50.0, streak * 10.0) + min(50.0, insights_reviewed * 5.0)
    return score

def _determine_tier(score: int) -> str:
    """Maps the numeric score to the required UX Tier."""
    if score <= 40: return "At Risk"
    if score <= 60: return "Needs Attention"
    if score <= 80: return "Strong"
    return "Optimized"

def _generate_microcopy(score: int, metrics: Dict[str, Any]) -> str:
    """Contextual microcopy for the UI based on score thresholds."""
    if 75 <= score < 80:
        return "One action away from reaching 80"
    
    # Default positive peer-pressure reinforcement
    waste_percentile = metrics.get("waste_percentile", 82)
    return f"You’re wasting less than {waste_percentile}% of users"

def generate_financial_health_score(metrics: Dict[str, Any], previous_score: int) -> Dict[str, Any]:
    """
    Main entry point to calculate the dynamic 0-100 Financial Health Score.
    Aggregates all 5 weighted components.
    """
    waste_score = _calc_waste_control(metrics) * 0.30
    savings_score = _calc_savings_impact(metrics) * 0.25
    stability_score = _calc_spending_stability(metrics) * 0.20
    optimization_score = _calc_optimization_actions(metrics) * 0.15
    engagement_score = _calc_engagement(metrics) * 0.10
    
    total_score = int(waste_score + savings_score + stability_score + optimization_score + engagement_score)
    total_score = min(100, max(0, total_score))
    
    delta = total_score - previous_score
    
    if delta > 0:
        delta_sign = "+"
        message = "You’re improving faster than last week"
    elif delta < 0:
        delta_sign = ""
        message = "Your efficiency dipped slightly this week"
    else:
        delta_sign = "+"
        message = "You're holding steady"
        
    return {
        "score": total_score,
        "status": _determine_tier(total_score),
        "delta": f"{delta_sign}{delta}",
        "message": message,
        "microcopy": _generate_microcopy(total_score, metrics),
        "breakdown": {
            "waste_control": int(waste_score / 0.30),
            "savings_impact": int(savings_score / 0.25),
            "spending_stability": int(stability_score / 0.20),
            "optimization_actions": int(optimization_score / 0.15),
            "engagement": int(engagement_score / 0.10)
        }
    }
