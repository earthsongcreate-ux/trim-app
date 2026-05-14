from fastapi import APIRouter, Depends
from app.models.user import User
from app.api.deps import get_current_user
from app.api.v1.endpoints.me import MeResponse, _to_me

router = APIRouter()

@router.get("/verify")
def verify_token(current_user: User = Depends(get_current_user)):
    return {
        "status": "success",
        "user_id": current_user.id,
        "email": current_user.email
    }


@router.post("/sync-user", response_model=MeResponse)
def sync_user(current_user: User = Depends(get_current_user)):
    return _to_me(current_user)
