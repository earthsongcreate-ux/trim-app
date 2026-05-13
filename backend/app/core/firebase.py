import json
import firebase_admin
from firebase_admin import credentials
from app.core.config import settings


def init_firebase() -> None:
    if firebase_admin._apps:
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
