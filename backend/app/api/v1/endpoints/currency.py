from fastapi import APIRouter, Depends
from pydantic import BaseModel
from app.api.deps import get_current_user
from app.models.user import User

router = APIRouter()


class CurrencyUpdateRequest(BaseModel):
    currencyCode: str


@router.put("/user/default")
async def set_user_currency(
    req: CurrencyUpdateRequest, current_user: User = Depends(get_current_user)
):
    return {"success": True, "currencyCode": req.currencyCode}
