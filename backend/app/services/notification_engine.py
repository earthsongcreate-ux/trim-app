from datetime import datetime
from typing import Dict, Any

class NotificationIntelligence:
    """
    Skill filter enforcing AI-Rules: All notification outputs must pass through 
    this intelligence layer to ensure optimal delivery and personalization.
    """
    @staticmethod
    def is_optimal_time(current_time: datetime) -> bool:
        """Avoids early morning (before 8 AM) and late night (after 9 PM)."""
        hour = current_time.hour
        return 8 <= hour < 21

    @staticmethod
    def check_frequency_limit(user_context: Dict[str, Any]) -> bool:
        """Enforces max 1-2 notifications per day to prevent alert fatigue."""
        notifications_today = user_context.get("notifications_sent_today", 0)
        return notifications_today < 2

    @staticmethod
    def should_suppress(user_context: Dict[str, Any], notification_type: str) -> bool:
        """
        Personalization logic: Stops or limits notifications if user ignores repeatedly.
        Adjusts frequency based on engagement scores.
        """
        ignored_count = user_context.get("consecutive_ignored_notifications", 0)
        # If highly disengaged, suppress everything EXCEPT high value alerts
        if ignored_count >= 3 and notification_type != "high_value_alert":
            return True
        return False

def generate_notification(notification_type: str, data: Dict[str, Any]) -> Dict[str, Any]:
    """Generates the structured notification payload based on the trigger type."""
    if notification_type == "high_value_alert":
        merchant = data.get("merchant", "A service")
        amount = data.get("amount", 0.0)
        
        # Determine specific sub-type message
        if data.get("alert_subtype") == "price_increase":
            yearly = amount * 12
            message = f"{merchant} just increased your price by ${int(amount)} (+${int(yearly)}/year)"
        else: 
            message = f"Duplicate charge of ${amount} detected from {merchant}"
            
        return {"title": "Action Required", "body": message, "type": notification_type}
        
    elif notification_type == "savings_win":
        amount = data.get("amount", 0.0)
        return {
            "title": "Savings unlocked!", 
            "body": f"You just saved ${int(amount)}/month 🎯", 
            "type": notification_type
        }
        
    elif notification_type == "weekly_digest":
        amount = data.get("amount", 0.0)
        return {
            "title": "Weekly Summary", 
            "body": f"You saved ${int(amount)} this week. Want to see how?", 
            "type": notification_type
        }
        
    elif notification_type == "missed_opportunity":
        merchant = data.get("merchant", "a service")
        return {
            "title": "Quick Win", 
            "body": f"You’re still paying for {merchant}. Cancel in 2 taps.", 
            "type": notification_type
        }
        
    return {}

def process_notification(
    user_id: int, 
    user_context: Dict[str, Any], 
    insight_confidence: str, 
    notification_type: str, 
    data: Dict[str, Any]
) -> Dict[str, Any]:
    """
    Main entry point for the Retention Notification System.
    Evaluates timing, daily limits, and intelligence rules before emitting an alert.
    """
    # RULE: Only send if confidence is high
    if insight_confidence.lower() != "high":
        return {"status": "suppressed", "reason": "confidence_too_low"}
        
    # ENFORCE AI-RULES: Pass through Notification Intelligence layer
    now = datetime.utcnow() # In production, convert to user's local timezone
    
    if not NotificationIntelligence.is_optimal_time(now):
         return {"status": "suppressed", "reason": "outside_optimal_hours"}
         
    if not NotificationIntelligence.check_frequency_limit(user_context):
         return {"status": "suppressed", "reason": "daily_limit_reached"}
         
    if NotificationIntelligence.should_suppress(user_context, notification_type):
         return {"status": "suppressed", "reason": "user_disengaged"}
         
    # Generate structured payload
    payload = generate_notification(notification_type, data)
    if not payload:
        return {"status": "error", "reason": "unknown_notification_type"}
        
    return {
        "status": "delivered",
        "payload": payload
    }
