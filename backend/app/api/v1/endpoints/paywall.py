from fastapi import APIRouter, Depends
from pydantic import BaseModel
from app.api.deps import get_current_user
from app.models.user import User

router = APIRouter()


@router.get("/evaluate")
async def evaluate_paywall(context: str, current_user: User = Depends(get_current_user)):
    return {
        "success": True,
        "showPaywall": False,
        "reason": None,
        "paywall": None,
    }


class PaywallInteractRequest(BaseModel):
    action: str


@router.post("/interact")
async def interact_with_paywall(
    req: PaywallInteractRequest, current_user: User = Depends(get_current_user)
):
    return {"success": True}
