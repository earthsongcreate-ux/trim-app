from cryptography.fernet import Fernet
import os
from app.core.config import settings

ENCRYPTION_KEY = (settings.ENCRYPTION_KEY or os.getenv("ENCRYPTION_KEY", "")).strip()

if not ENCRYPTION_KEY:
    if settings.ENV.lower() == "production":
        raise RuntimeError("ENCRYPTION_KEY is required in production")
    ENCRYPTION_KEY = Fernet.generate_key().decode("utf-8")

fernet = Fernet(ENCRYPTION_KEY.encode("utf-8"))

def encrypt(data: str) -> str:
    return fernet.encrypt(data.encode("utf-8")).decode("utf-8")

def decrypt(data: str) -> str:
    return fernet.decrypt(data.encode("utf-8")).decode("utf-8")
