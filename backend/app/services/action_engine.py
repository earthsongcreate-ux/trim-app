from typing import Dict, List, Any

def generate_actions_for_insight(insight: Dict[str, Any]) -> Dict[str, Any]:
    """
    Analyzes a financial insight and attaches a list of structured, 
    one-tap actions tailored to the specific context.
    """
    actions = []
    
    insight_type = insight.get("type", "")
    amount = insight.get("amount", 0.0)
    
    # 1. CANCEL ACTION
    # Ideal for unused subscriptions or general subscriptions
    if insight_type in ["unused_subscription", "subscription"]:
        actions.append({
            "action": "cancel",
            "label": "Cancel subscription",
            "confidence": "high" if insight_type == "unused_subscription" else "medium"
        })
        
    # 2. NEGOTIATE ACTION
    # Ideal for price increases or high-cost recurring services (>$40)
    if insight_type == "price_increase" or (insight_type == "subscription" and amount > 40.0):
        actions.append({
            "action": "negotiate",
            "label": "Try to reduce cost",
            "confidence": "high" if insight_type == "price_increase" else "medium"
        })
        
    # 3. MARK AS VALID ACTION
    # Captures user feedback to improve system learning/confidence
    if insight_type in ["duplicate", "subscription", "price_increase"]:
         actions.append({
            "action": "mark_as_valid",
            "label": "Keep it (Valid)",
            "confidence": "high"
        })
        
    # 4. IGNORE / DISMISS ACTION
    # Always allow the user to dismiss an insight without taking action
    actions.append({
        "action": "ignore",
        "label": "Dismiss",
        "confidence": "high"
    })
    
    # Attach actions to the original insight
    actionable_insight = insight.copy()
    actionable_insight["actions"] = actions
    
    return actionable_insight

def process_insights_for_action(insights: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Processes a list of raw insights and maps contextual actions to each one.
    Designed to execute in O(n) time, ensuring responses take < 3 seconds.
    """
    return [generate_actions_for_insight(i) for i in insights]
