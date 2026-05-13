from fastapi import APIRouter, Depends
from app.api.deps import get_current_user
from app.models.user import User

router = APIRouter()


@router.get("/impact")
async def get_savings_impact(current_user: User = Depends(get_current_user)):
    return {
        "success": True,
        "total_saved": 0.0,
        "monthly_savings": 0.0,
        "annual_projection": 0.0,
        "recent_wins": [],
    }
