from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.firebase import init_firebase
from app.core.database import engine, Base
import app.models
import os

from app.api.v1.api import api_router

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

origins = [o.strip() for o in (settings.CORS_ORIGINS or "").split(",") if o.strip()]
is_production = settings.ENV.lower() == "production"
allow_all = (not origins) and (not is_production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if allow_all else origins,
    allow_credentials=False if allow_all else True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix=settings.API_V1_STR)

@app.on_event("startup")
async def _startup() -> None:
    init_firebase()
    auto_create = os.getenv("AUTO_CREATE_TABLES", "true").lower() == "true"
    if not is_production and auto_create:
        Base.metadata.create_all(bind=engine)

@app.get("/health")
async def health_check():
    return {"status": "ok"}
