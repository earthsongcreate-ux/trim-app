from fastapi import APIRouter

router = APIRouter()

@router.get("/insights")
async def get_insights():
    return {"savings_identified": 842.0, "opportunities": []}
