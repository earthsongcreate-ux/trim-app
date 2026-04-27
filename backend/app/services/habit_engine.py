from datetime import datetime
from typing import Dict, Any, List

def evaluate_triggers(user_id: int, user_context: Dict[str, Any]) -> List[Dict[str, Any]]:
    """
    Evaluates the user's current context against predefined habit triggers.
    Designed to run via a background worker or upon app launch.
    """
    triggers = []
    
    # 1. New Insight Trigger (Variable Reward Anticipation)
    new_insights = user_context.get("new_insights_count", 0)
    if new_insights > 0:
        triggers.append({
            "trigger_type": "new_insight",
            "priority": "high",
            "message": f"We found {new_insights} new way{'s' if new_insights > 1 else ''} to optimize your spending."
        })
        
    # 2. Savings Milestone Trigger (Achievement Motivation)
    total_savings = user_context.get("total_savings", 0.0)
    last_milestone = user_context.get("last_milestone_notified", 0.0)
    
    # Triggers every $50 or $100 bracket crossed
    if total_savings - last_milestone >= 50.0:
        triggers.append({
            "trigger_type": "savings_milestone",
            "priority": "high",
            "message": f"You just crossed ${int(total_savings)} in total savings! Tap to see your impact."
        })
        
    # 3. Weekly Summary Trigger (Predictable Routine)
    last_summary_date = user_context.get("last_weekly_summary_date")
    # If no summary sent yet, or it's been 7 days
    if not last_summary_date or (datetime.utcnow() - last_summary_date).days >= 7:
        triggers.append({
            "trigger_type": "weekly_summary",
            "priority": "medium",
            "message": "Your weekly financial summary is ready."
        })
        
    return triggers

def generate_reward_payload(action_type: str, action_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Generates the psychological reward payload returned to the frontend
    after a user successfully completes a positive financial action.
    """
    reward = {
        "animation": None,
        "message": None,
        "streak_update": None
    }
    
    # Scenario A: User executed a financial action (Cancel/Negotiate)
    if action_type in ["cancel_success", "negotiate_success"]:
        saved_amount = action_data.get("saved_amount", 0.0)
        smart_decisions = action_data.get("smart_decisions_this_week", 0) + 1
        
        # High-dopamine visual reward
        reward["animation"] = "savings_increase_burst"
        reward["message"] = f"Awesome! You just saved ${int(saved_amount)}/month."
        
        # Progress and identity reinforcement
        reward["streak_update"] = {
            "count": smart_decisions,
            "message": f"{smart_decisions} smart financial decision{'s' if smart_decisions > 1 else ''} this week. You're improving!"
        }
        
    # Scenario B: User simply engaged with the app (Reviewed insights/summary)
    elif action_type == "review_insights":
        streak_days = action_data.get("login_streak_days", 0) + 1
        
        # Subtle visual reward to prevent dopamine exhaustion
        reward["animation"] = "subtle_glow_pulse"
        reward["message"] = "Staying on top of your money."
        
        # Build habit through consistency tracking
        if streak_days >= 2:
            reward["streak_update"] = {
                "count": streak_days,
                "message": f"{streak_days} day streak! Consistency is key."
            }
            
    return reward

def process_habit_loop(user_id: int, event: str, payload: Dict[str, Any]) -> Dict[str, Any]:
    """
    Main entry point for the Habit Engine.
    Maps an incoming event to either evaluating triggers or generating rewards.
    """
    if event == "evaluate_state":
        # Usually called silently in the background
        return {"triggers": evaluate_triggers(user_id, payload)}
    
    elif event == "action_completed":
        # Called immediately after the user taps "Yes" on an execution workflow
        action_type = payload.get("action_type")
        return {"reward_payload": generate_reward_payload(action_type, payload)}
        
    else:
        return {"error": "Unknown habit loop event"}
