from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.insight import Insight

router = APIRouter()

@router.get("/insights/generate")
@router.get("/insights")
async def get_insights(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    insights = db.query(Insight).filter(Insight.user_id == current_user.id).all()
    
    total_savings = sum(i.potential_savings for i in insights if i.potential_savings)
    return {
        "success": True,
        "count": len(insights),
        "suppressed": 0,
        "savings_identified": total_savings,
        "insights": [
            {
                "id": str(i.id),
                "type": "saving_opportunity" if "subscription" in i.type else "unusual_spending",
                "title": "Cancel Unused Subscription" if "subscription" in i.type else "Review Spending",
                "description": f"We detected a recurring charge for {i.type.split('_')[-1] if '_' in i.type else 'a service'}. Consider cancelling it to save money.",
                "monthlyImpact": float(i.potential_savings or 0),
                "annualImpact": float((i.potential_savings or 0) * 12),
                "primaryAction": "cancel" if "subscription" in i.type else "review",
                "confidence": "high" if i.confidence_score and i.confidence_score > 0.8 else "medium",
                "confidenceScore": int((i.confidence_score or 0.8) * 100),
                "reasoning": "Detected from Plaid transaction history",
                "showToUser": True,
                "merchant": i.type.split('_')[-1] if '_' in i.type else None
            } for i in insights
        ]
    }
