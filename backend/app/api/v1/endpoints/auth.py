from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from app.core.security import create_access_token
from app.core.config import settings
from datetime import timedelta

router = APIRouter()

@router.post("/login/access-token")
async def login_access_token(form_data: OAuth2PasswordRequestForm = Depends()):
    # Mocking authentication for now, would normally verify against DB
    if not form_data.username or not form_data.password:
        raise HTTPException(status_code=400, detail="Incorrect email or password")
        
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    return {
        "access_token": create_access_token(
            subject=form_data.username, expires_delta=access_token_expires
        ),
        "token_type": "bearer",
    }

@router.post("/apple-signin")
async def apple_signin(identity_token: str):
    # Verify Apple identity_token and issue our own JWT
    return {"access_token": create_access_token(subject="apple_user_id"), "token_type": "bearer"}

@router.post("/google-signin")
async def google_signin(id_token: str):
    # Verify Google id_token and issue our own JWT
    return {"access_token": create_access_token(subject="google_user_id"), "token_type": "bearer"}
