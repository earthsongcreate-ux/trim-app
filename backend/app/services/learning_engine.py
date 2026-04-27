from datetime import datetime
from typing import Dict, Any, List

# In-memory data store representing a persistent 'feedback' database table.
# In production, this would be a PostgreSQL table tracking user behavioral interactions.
feedback_store: List[Dict[str, Any]] = []

def record_feedback(user_id: int, merchant: str, action_taken: str, result: str) -> None:
    """
    Records a user's interaction with an insight or execution workflow.
    
    Expected actions: "confirm", "reject", "cancel", "ignore"
    Expected results: "success", "fail", "dismissed"
    """
    feedback_entry = {
        "user_id": user_id,
        "merchant": merchant,
        "action_taken": action_taken,
        "result": result,
        "timestamp": datetime.utcnow()
    }
    feedback_store.append(feedback_entry)

def _calculate_global_modifier(merchant: str) -> float:
    """
    Simulates a Global Learning aggregation.
    In production, this queries aggregated stats across all users to improve 
    global merchant classification rules.
    """
    # E.g., if a merchant is globally rejected as a subscription by 80% of users,
    # the engine learns to lower baseline confidence for everyone.
    global_rejections = [f for f in feedback_store if f["merchant"] == merchant and f["action_taken"] == "reject"]
    if len(global_rejections) > 10:
        return -0.20
    return 0.0

def adapt_insight(user_id: int, insight: Dict[str, Any]) -> Dict[str, Any]:
    """
    Applies the adaptive intelligence layer to an incoming insight.
    Adjusts confidence scores and suppresses irrelevant insights based on user history.
    """
    merchant = insight.get("merchant")
    if not merchant:
         return insight
         
    # Fetch historical feedback for this specific user and merchant
    user_history = [f for f in feedback_store if f["user_id"] == user_id and f["merchant"] == merchant]
    
    confidence_modifier = 0.0
    suppress = False
    
    for record in user_history:
        action = record["action_taken"]
        result = record["result"]
        
        # 1. CONFIDENCE ADJUSTMENT
        if action == "confirm":
            confidence_modifier += 0.15
        elif action == "reject":
            confidence_modifier -= 0.20
            
        # 2. PERSONALIZATION & SUPPRESSION
        # If the user consistently ignores a recommendation to cancel something (e.g. Spotify),
        # the system learns it is vital to them and suppresses future cancellation nudges.
        if action == "ignore" and insight.get("type") == "unused_subscription":
            suppress = True
            
        # If they successfully cancelled it in the past, stop showing it as an active subscription
        if action == "cancel" and result == "success":
            suppress = True

    # 3. GLOBAL LEARNING
    global_modifier = _calculate_global_modifier(merchant)
    
    if suppress:
        insight["suppressed"] = True
        return insight
        
    # Translate text confidence to float for math operations
    conf_map = {"high": 0.9, "medium": 0.6, "low": 0.3}
    current_confidence = conf_map.get(str(insight.get("confidence", "low")).lower(), 0.5)
    
    # Calculate new bounded confidence score [0.0, 1.0]
    new_confidence = min(1.0, max(0.0, current_confidence + confidence_modifier + global_modifier))
    
    # Translate back to text enum
    if new_confidence >= 0.8:
        insight["confidence"] = "high"
    elif new_confidence >= 0.5:
        insight["confidence"] = "medium"
    else:
        insight["confidence"] = "low"
        
    insight["suppressed"] = False
    return insight

def apply_learning_layer(user_id: int, insights: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Processes an array of generated insights through the feedback learning engine.
    Filters out any suppressed insights to protect the UX from annoyance.
    """
    adapted = [adapt_insight(user_id, i) for i in insights]
    
    # Filter out suppressed insights so they never reach the UI
    return [i for i in adapted if not i.get("suppressed", False)]
