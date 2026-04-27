import hashlib
from typing import Dict, Any

def generate_referral_code(user_id: int) -> str:
    """
    Generates a unique, deterministic, and short human-readable referral 
    code for the user (e.g. 'A7F92B').
    """
    hash_object = hashlib.md5(str(user_id).encode())
    return hash_object.hexdigest()[:6].upper()

def evaluate_share_trigger(user_id: int, action_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Evaluates a user's recent action (like saving money or leveling up their score)
    to determine if a frictionless "share prompt" should be injected into the UI.
    """
    action_type = action_data.get("action_type")
    
    # 1. Triggered after successfully saving money
    if action_type == "savings_success":
        amount_saved = action_data.get("amount_saved", 0)
        # Minimum threshold to brag about
        if amount_saved >= 10:
            return _generate_savings_share_payload(user_id, amount_saved)
            
    # 2. Triggered after hitting a new Health Score tier
    elif action_type == "score_tier_up":
        new_score = action_data.get("new_score", 0)
        # Only trigger for 'Strong' (61+) or 'Optimized' (81+) tiers
        if new_score >= 61:
            return _generate_score_share_payload(user_id, new_score)
            
    return {"should_prompt": False}

def _generate_savings_share_payload(user_id: int, amount_saved: float) -> Dict[str, Any]:
    """Generates the UI configuration for a 'Savings Share' card."""
    ref_code = generate_referral_code(user_id)
    return {
        "should_prompt": True,
        "prompt_message": "Want to share this win?",
        "share_data": {
            "type": "savings_share",
            "text": f"I just saved ${int(amount_saved)} this month using Trim. 💸",
            "url": f"https://trim.app/invite/{ref_code}",
            "ui_config": {
                "theme": "premium_dark",
                "highlight_color": "#16A34A", # Trim Green
                "highlight_text": f"${int(amount_saved)}"
            }
        },
        "incentive_message": "Get 1 free month of Premium per referral"
    }

def _generate_score_share_payload(user_id: int, score: int) -> Dict[str, Any]:
    """Generates the UI configuration for a 'Score Share' card."""
    ref_code = generate_referral_code(user_id)
    return {
        "should_prompt": True,
        "prompt_message": "Want to share this win?",
        "share_data": {
            "type": "score_share",
            "text": f"My financial health score just hit {score} 🔥",
            "url": f"https://trim.app/invite/{ref_code}",
            "ui_config": {
                "theme": "premium_dark",
                "highlight_color": "#16A34A",
                "highlight_text": str(score)
            }
        },
        "incentive_message": "Share your score and unlock advanced insights"
    }

def process_referral_conversion(referral_code: str, new_user_id: int) -> Dict[str, Any]:
    """
    Called when a new user signs up. Tracks the install and conversion,
    and grants the incentive to the referring user.
    """
    # In production: Query DB to find the original referring user_id by referral_code
    
    # Execute Reward Logic
    reward_granted = "1_month_premium"
    # Execute DB update to grant premium to the referrer here...
    
    return {
        "status": "success",
        "referring_code": referral_code,
        "new_user_id": new_user_id,
        "event_tracked": "install_conversion",
        "reward_granted": reward_granted
    }
