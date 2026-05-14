from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from app.core.database import get_db
from firebase_admin import auth
from app.models.user import User

security = HTTPBearer()

def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    token = credentials.credentials
    try:
        decoded_token = auth.verify_id_token(token)
        email = (decoded_token.get("email") or "").strip().lower()
        firebase_uid = (decoded_token.get("uid") or decoded_token.get("user_id") or decoded_token.get("sub") or "").strip()

        if not firebase_uid or not email:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication credentials",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        user = db.query(User).filter(User.firebase_uid == firebase_uid).first()
        if not user:
            user = db.query(User).filter(User.email == email).first()
        if not user:
            user = User(email=email, firebase_uid=firebase_uid)
            db.add(user)
            db.commit()
            db.refresh(user)
        else:
            changed = False
            if not user.firebase_uid:
                user.firebase_uid = firebase_uid
                changed = True
            if user.email != email and email:
                user.email = email
                changed = True
            if changed:
                db.add(user)
                db.commit()
                db.refresh(user)
        return user
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
