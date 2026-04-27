from fastapi import APIRouter

router = APIRouter()

@router.get("/active")
async def active_subscriptions():
    return []

@router.post("/cancel")
async def cancel_subscription(subscription_id: str):
    return {"status": "cancellation_requested"}
