from fastapi import APIRouter

router = APIRouter()

@router.post("/push")
async def send_push_notification():
    return {"status": "sent"}
