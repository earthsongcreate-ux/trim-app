from fastapi import APIRouter, Depends
from app.models.user import User
from app.api.deps import get_current_user

router = APIRouter()

@router.get("/verify")
def verify_token(current_user: User = Depends(get_current_user)):
    return {
        "status": "success",
        "user_id": current_user.id,
        "email": current_user.email
    }
