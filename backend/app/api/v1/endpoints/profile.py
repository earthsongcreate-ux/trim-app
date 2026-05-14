from fastapi import APIRouter, Depends
from pydantic import BaseModel
from typing import Optional
from datetime import datetime, timezone
from sqlalchemy.orm import Session
from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.models.user_profile import UserProfile


router = APIRouter()


class UserProfileResponse(BaseModel):
    uid: str
    email: str
    createdAt: Optional[str] = None
    firstName: Optional[str] = None
    monthlyIncome: int
    monthlySavingsGoal: int
    onboardingComplete: bool
    isPremium: bool
    subscriptionPlan: Optional[str] = None
    subscriptionStatus: Optional[str] = None
    trialDays: Optional[int] = None
    trialStartedAt: Optional[str] = None
    isFoundingMember: bool
    foundingMemberNumber: Optional[int] = None
    lockedAnnualPriceCents: Optional[int] = None
    lockedAnnualPriceCurrency: Optional[str] = None
    hasEarlySupporterBadge: bool
    futurePremiumFeaturesIncluded: bool


class UpdateUserProfileRequest(BaseModel):
    firstName: Optional[str] = None
    monthlyIncome: Optional[int] = None
    monthlySavingsGoal: Optional[int] = None
    onboardingComplete: Optional[bool] = None


class FoundingAnnualOfferStateResponse(BaseModel):
    limit: int
    claimedCount: int


class StartTrialRequest(BaseModel):
    plan: str
    trialDays: int
    annualPriceCents: int
    annualCurrency: str


def _iso(dt: Optional[datetime]) -> Optional[str]:
    if not dt:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc).isoformat()


def _get_or_create_profile(db: Session, user: User) -> UserProfile:
    profile = db.query(UserProfile).filter(UserProfile.user_id == user.id).first()
    if profile:
        return profile
    profile = UserProfile(user_id=user.id)
    db.add(profile)
    db.commit()
    db.refresh(profile)
    return profile


def _to_response(user: User, profile: UserProfile) -> UserProfileResponse:
    firebase_uid = getattr(user, "firebase_uid", None) or ""
    return UserProfileResponse(
        uid=firebase_uid,
        email=user.email,
        createdAt=_iso(profile.created_at),
        firstName=profile.first_name,
        monthlyIncome=profile.monthly_income or 0,
        monthlySavingsGoal=profile.monthly_savings_goal or 0,
        onboardingComplete=bool(profile.onboarding_complete),
        isPremium=bool(profile.is_premium),
        subscriptionPlan=profile.subscription_plan,
        subscriptionStatus=profile.subscription_status,
        trialDays=profile.trial_days,
        trialStartedAt=_iso(profile.trial_started_at),
        isFoundingMember=bool(profile.is_founding_member),
        foundingMemberNumber=profile.founding_member_number,
        lockedAnnualPriceCents=profile.locked_annual_price_cents,
        lockedAnnualPriceCurrency=profile.locked_annual_price_currency,
        hasEarlySupporterBadge=bool(profile.has_early_supporter_badge),
        futurePremiumFeaturesIncluded=bool(profile.future_premium_features_included),
    )


@router.get("/me", response_model=UserProfileResponse)
async def get_my_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    profile = _get_or_create_profile(db, current_user)
    return _to_response(current_user, profile)


@router.patch("/me", response_model=UserProfileResponse)
async def update_my_profile(
    req: UpdateUserProfileRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    profile = _get_or_create_profile(db, current_user)

    if req.firstName is not None:
        cleaned = req.firstName.strip()
        profile.first_name = cleaned if cleaned else None
        current_user.full_name = profile.first_name
    if req.monthlyIncome is not None:
        profile.monthly_income = max(int(req.monthlyIncome), 0)
    if req.monthlySavingsGoal is not None:
        profile.monthly_savings_goal = max(int(req.monthlySavingsGoal), 0)
    if req.onboardingComplete is not None:
        profile.onboarding_complete = bool(req.onboardingComplete)
        current_user.onboarding_complete = bool(req.onboardingComplete)

    db.add(current_user)
    db.add(profile)
    db.commit()
    db.refresh(profile)
    db.refresh(current_user)
    return _to_response(current_user, profile)


@router.get("/founding-annual-offer", response_model=FoundingAnnualOfferStateResponse)
async def get_founding_annual_offer_state(db: Session = Depends(get_db)):
    limit = 250
    claimed = (
        db.query(UserProfile)
        .filter(UserProfile.is_founding_member.is_(True))
        .count()
    )
    return FoundingAnnualOfferStateResponse(limit=limit, claimedCount=claimed)


@router.post("/start-trial", response_model=UserProfileResponse)
async def start_trial(
    req: StartTrialRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    profile = _get_or_create_profile(db, current_user)

    plan = (req.plan or "").strip().lower()
    if plan not in ("monthly", "annual"):
        plan = "monthly"

    profile.is_premium = True
    profile.subscription_plan = plan
    profile.subscription_status = "trial"
    profile.trial_days = int(req.trialDays)
    profile.trial_started_at = datetime.now(timezone.utc)
    current_user.plan = plan
    db.add(current_user)

    if plan == "annual":
        limit = 250
        claimed = (
            db.query(UserProfile)
            .filter(UserProfile.is_founding_member.is_(True))
            .count()
        )
        if claimed < limit and not profile.is_founding_member:
            member_number = claimed + 1
            profile.is_founding_member = True
            profile.founding_member_number = member_number
            profile.locked_annual_price_cents = int(req.annualPriceCents)
            profile.locked_annual_price_currency = req.annualCurrency
            profile.has_early_supporter_badge = True
            profile.future_premium_features_included = True

    db.add(profile)
    db.commit()
    db.refresh(profile)
    db.refresh(current_user)
    return _to_response(current_user, profile)
