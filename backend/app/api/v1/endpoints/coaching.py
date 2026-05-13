from fastapi import APIRouter, Depends
from app.api.deps import get_current_user
from app.models.user import User

router = APIRouter()


@router.get("")
async def get_coaching(current_user: User = Depends(get_current_user)):
    coaching = {
        "priority_action": {
            "type": "save_money",
            "title": "Review recurring charges",
            "description": "Connect your bank account to detect recurring subscriptions and potential savings.",
            "impact": "high",
            "confidence": "high",
            "actionData": None,
        },
        "secondary_actions": [],
    }

    return {"success": True, "coaching": coaching}
