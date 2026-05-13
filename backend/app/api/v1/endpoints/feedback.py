from fastapi import APIRouter, Depends
from pydantic import BaseModel
from typing import Optional
from datetime import datetime, timezone
from app.api.deps import get_current_user
from app.models.user import User

router = APIRouter()


class FeedbackPrediction(BaseModel):
    merchant: Optional[str] = None
    category: Optional[str] = None
    isRecurring: Optional[bool] = None


class FeedbackCorrection(BaseModel):
    merchant: Optional[str] = None
    category: Optional[str] = None
    isRecurring: Optional[bool] = None


class FeedbackRequest(BaseModel):
    userId: str
    targetId: str
    targetType: str
    feedbackType: str
    originalPrediction: FeedbackPrediction
    userCorrection: Optional[FeedbackCorrection] = None


@router.post("")
async def submit_feedback(
    req: FeedbackRequest, current_user: User = Depends(get_current_user)
):
    return {
        "success": True,
        "feedback": {
            "feedbackId": f"{current_user.id}:{req.targetId}",
            "feedbackType": req.feedbackType,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        },
        "learning": {
            "applied": False,
            "userOverrideSet": False,
            "globalCorrectionTracked": False,
            "confidenceAdjusted": False,
        },
    }
