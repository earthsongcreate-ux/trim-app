from fastapi import APIRouter

router = APIRouter()

@router.post("/ingest")
async def ingest_transactions():
    return {"status": "processing"}

@router.get("/")
async def list_transactions():
    return []
