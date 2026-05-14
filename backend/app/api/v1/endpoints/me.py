from fastapi import APIRouter, Depends
from pydantic import BaseModel
from typing import Optional
from datetime import datetime, timezone
from sqlalchemy.orm import Session
from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.user import User


router = APIRouter()


def _iso(dt: Optional[datetime]) -> Optional[str]:
    if not dt:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc).isoformat()


class MeResponse(BaseModel):
    id: int
    firebase_uid: Optional[str] = None
    email: str
    full_name: Optional[str] = None
    created_at: Optional[str] = None
    updated_at: Optional[str] = None
    plan: Optional[str] = None
    onboarding_complete: bool


class UpdateMeRequest(BaseModel):
    full_name: Optional[str] = None
    plan: Optional[str] = None
    onboarding_complete: Optional[bool] = None


def _to_me(user: User) -> MeResponse:
    return MeResponse(
        id=user.id,
        firebase_uid=user.firebase_uid,
        email=user.email,
        full_name=user.full_name,
        created_at=_iso(user.created_at),
        updated_at=_iso(user.updated_at),
        plan=user.plan,
        onboarding_complete=bool(user.onboarding_complete),
    )


@router.get("/me", response_model=MeResponse)
async def get_me(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _ = db
    return _to_me(current_user)


@router.patch("/me", response_model=MeResponse)
async def update_me(
    req: UpdateMeRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    changed = False
    if req.full_name is not None:
        cleaned = req.full_name.strip()
        current_user.full_name = cleaned if cleaned else None
        changed = True
    if req.plan is not None:
        plan = req.plan.strip().lower()
        current_user.plan = plan if plan else None
        changed = True
    if req.onboarding_complete is not None:
        current_user.onboarding_complete = bool(req.onboarding_complete)
        changed = True

    if changed:
        db.add(current_user)
        db.commit()
        db.refresh(current_user)
    return _to_me(current_user)

