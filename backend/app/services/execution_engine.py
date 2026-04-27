from typing import Dict, Any

# Knowledge base of provider-specific cancellation and negotiation metadata
PROVIDER_DATA = {
    "Netflix": {
        "cancel_url": "https://www.netflix.com/cancelplan",
        "cancel_steps": [
            "Log in to your Netflix account",
            "Go to Account Settings",
            "Select 'Cancel Membership' under Plan Details",
            "Confirm cancellation"
        ],
        "negotiate_probability": 0.05  # Standardized pricing, low negotiation success
    },
    "Spotify": {
        "cancel_url": "https://www.spotify.com/account/cancel/",
        "cancel_steps": [
            "Log in to your Spotify account page",
            "Scroll to 'Your plan' and click 'Change plan'",
            "Scroll to 'Spotify Free' and click 'Cancel Premium'",
            "Confirm cancellation"
        ],
        "negotiate_probability": 0.10
    },
    "Comcast": {
        "cancel_url": "https://www.xfinity.com/support/cancel",
        "cancel_steps": [
            "Log in to your Xfinity account",
            "Navigate to Services",
            "Select 'Manage Plan'",
            "Follow the cancellation prompts or start a live chat"
        ],
        "negotiate_probability": 0.85  # High success rate for retention offers
    }
}

DEFAULT_PROVIDER = {
    "cancel_url": None,
    "cancel_steps": [
        "Go to the provider's website and log in",
        "Navigate to your Account or Billing settings",
        "Look for 'Manage Subscription' or 'Cancel Plan'",
        "Follow the steps to confirm cancellation"
    ],
    "negotiate_probability": 0.50
}

def generate_cancel_workflow(merchant: str) -> Dict[str, Any]:
    """Generates a frictionless cancellation flow for a specific merchant."""
    provider = PROVIDER_DATA.get(merchant, DEFAULT_PROVIDER)
    
    return {
        "workflow_type": "cancel",
        "merchant": merchant,
        "confirmation_message": "We’ll guide you through cancellation",
        "options": {
            "deep_link": provider["cancel_url"],
            "steps": provider["cancel_steps"],
            "pre_filled_message": f"Hello, I would like to cancel my {merchant} subscription immediately. Please process this and confirm when my account is closed."
        },
        "post_action": get_confirmation_prompt()
    }

def generate_negotiation_workflow(merchant: str) -> Dict[str, Any]:
    """Generates an automated/guided negotiation flow for a specific merchant."""
    provider = PROVIDER_DATA.get(merchant, DEFAULT_PROVIDER)
    prob = int(provider["negotiate_probability"] * 100)
    
    return {
        "workflow_type": "negotiate",
        "merchant": merchant,
        "probability_message": f"{prob}% chance of saving",
        "options": {
            "script": f"Hi, I’ve been a customer for a while and noticed my bill for {merchant} increased. Are there any discounts or retention offers available?",
            "chat_template": "I am reviewing my monthly expenses and looking to reduce my bill. Can you apply any current promotions or loyalty discounts to my account?",
            "automated_email": f"Subject: Request to Review Account Billing\n\nHello {merchant} Support,\n\nI am writing to request a review of my current billing rate. As a long-time customer, I am looking for ways to reduce my monthly cost. Please let me know what retention offers or discounts can be applied to my account.\n\nThank you."
        },
        "post_action": get_confirmation_prompt()
    }

def get_confirmation_prompt() -> Dict[str, Any]:
    """Standardized post-action feedback loop to track successful ROI."""
    return {
        "prompt": "Did this work?",
        "choices": [
            {
                "label": "Yes",
                "action": "record_savings"
            },
            {
                "label": "No",
                "action": "suggest_alternative"
            }
        ]
    }

def build_execution_payload(action: str, merchant: str) -> Dict[str, Any]:
    """
    Main entry point for the Execution Engine. 
    Routes the requested action to the correct workflow generator.
    """
    if action == "cancel":
        return generate_cancel_workflow(merchant)
    elif action == "negotiate":
        return generate_negotiation_workflow(merchant)
    else:
        return {"error": f"Unsupported action type: {action}"}
