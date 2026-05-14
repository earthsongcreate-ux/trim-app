from fastapi import APIRouter
from app.api.v1.endpoints import (
    auth,
    transactions,
    intelligence,
    subscriptions,
    notifications,
    plaid,
    coaching,
    savings,
    paywall,
    feedback,
    currency,
    profile,
    me,
)

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(me.router, tags=["me"])
api_router.include_router(transactions.router, prefix="/transactions", tags=["transactions"])
api_router.include_router(intelligence.router, prefix="/intelligence", tags=["intelligence"])
api_router.include_router(subscriptions.router, prefix="/subscriptions", tags=["subscriptions"])
api_router.include_router(notifications.router, prefix="/notifications", tags=["notifications"])
api_router.include_router(plaid.router, prefix="/plaid", tags=["plaid"])
api_router.include_router(coaching.router, prefix="/coaching", tags=["coaching"])
api_router.include_router(savings.router, prefix="/savings", tags=["savings"])
api_router.include_router(paywall.router, prefix="/paywall", tags=["paywall"])
api_router.include_router(feedback.router, prefix="/feedback", tags=["feedback"])
api_router.include_router(currency.router, prefix="/currency", tags=["currency"])
api_router.include_router(profile.router, prefix="/profile", tags=["profile"])
