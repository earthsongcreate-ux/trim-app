from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings

from app.api.v1.api import api_router

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, restrict to app domains
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix=settings.API_V1_STR)

@app.get("/health")
async def health_check():
    return {"status": "ok"}

from fastapi import Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.core.database import get_db

@app.get("/db-test")
def test_db_connection(db: Session = Depends(get_db)):
    try:
        # Simple query to test the connection
        db.execute(text("SELECT 1"))
        return {"status": "success", "message": "Connected to database successfully"}
    except Exception as e:
        return {"status": "error", "message": str(e)}
