import json
import firebase_admin
from firebase_admin import credentials
from app.core.config import settings


def init_firebase() -> None:
    if firebase_admin._apps:
        return

    if settings.FIREBASE_PROJECT_ID and settings.FIREBASE_CLIENT_EMAIL and settings.FIREBASE_PRIVATE_KEY:
        private_key = settings.FIREBASE_PRIVATE_KEY.replace("\\n", "\n")
        info = {
            "type": "service_account",
            "project_id": settings.FIREBASE_PROJECT_ID,
            "client_email": settings.FIREBASE_CLIENT_EMAIL,
            "private_key": private_key,
            "token_uri": "https://oauth2.googleapis.com/token",
        }
        cred = credentials.Certificate(info)
        firebase_admin.initialize_app(cred)
        return

    if settings.FIREBASE_SERVICE_ACCOUNT_JSON:
        try:
            info = json.loads(settings.FIREBASE_SERVICE_ACCOUNT_JSON)
            cred = credentials.Certificate(info)
            firebase_admin.initialize_app(cred)
            return
        except Exception:
            firebase_admin.initialize_app()
            return

    if settings.FIREBASE_SERVICE_ACCOUNT_PATH:
        cred = credentials.Certificate(settings.FIREBASE_SERVICE_ACCOUNT_PATH)
        firebase_admin.initialize_app(cred)
        return

    firebase_admin.initialize_app()
