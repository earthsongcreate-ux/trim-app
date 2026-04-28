from cryptography.fernet import Fernet
import os
from app.core.config import settings

# In production, this should be a 32-url-safe-base64-encoded bytes string
# Generate using Fernet.generate_key() and store in ENV.
# Default fallback for local testing if not provided in settings
ENCRYPTION_KEY = os.getenv("ENCRYPTION_KEY", Fernet.generate_key().decode("utf-8"))
fernet = Fernet(ENCRYPTION_KEY.encode("utf-8"))

def encrypt(data: str) -> str:
    return fernet.encrypt(data.encode("utf-8")).decode("utf-8")

def decrypt(data: str) -> str:
    return fernet.decrypt(data.encode("utf-8")).decode("utf-8")
