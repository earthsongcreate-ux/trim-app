from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session
from datetime import date, timedelta
from app.services import plaid_service
from app.core.database import get_db
from app.models.plaid_item import PlaidItem

router = APIRouter()

class ExchangeRequest(BaseModel):
    public_token: str

@router.post("/create-link-token")
async def create_link_token_endpoint():
    try:
        link_token = plaid_service.create_link_token()
        return {"link_token": link_token}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/exchange-token")
async def exchange_token_endpoint(req: ExchangeRequest, db: Session = Depends(get_db)):
    try:
        # Exchange token via Plaid API
        exchange_response = plaid_service.exchange_public_token(req.public_token)
        
        # Securely store the access_token in the database
        plaid_item = PlaidItem(
            user_id=1,  # Mocked user ID for testing. Replace with JWT extracted user.
            item_id=exchange_response['item_id'],
            access_token=exchange_response['access_token']
        )
        db.add(plaid_item)
        db.commit()
        
        # NEVER return access_token or item_id to the frontend
        return {"status": "connected"}
    except Exception as e:
        db.rollback()
        # Logging of exception should occur here (safely stripped of sensitive data)
        raise HTTPException(status_code=500, detail="Failed to exchange and connect bank account")

@router.get("/transactions")
async def fetch_transactions_endpoint(db: Session = Depends(get_db)):
    try:
        user_id = 1 # Mocked authenticated user
        
        # Retrieve secure access token
        plaid_item = db.query(PlaidItem).filter(PlaidItem.user_id == user_id).first()
        if not plaid_item:
            raise HTTPException(status_code=400, detail="No bank account connected")
            
        # 90 Day window
        end_date = date.today()
        start_date = end_date - timedelta(days=90)
        
        # Call Plaid
        transactions = plaid_service.fetch_transactions(
            access_token=plaid_item.access_token,
            start_date=start_date,
            end_date=end_date
        )
        
        # Transform Response
        simplified_txns = []
        for txn in transactions:
            simplified_txns.append({
                "name": txn['name'],
                "amount": txn['amount'],
                "date": str(txn['date']),
                "category": txn['category'][0] if txn.get('category') and len(txn['category']) > 0 else "uncategorized"
            })
            
        return simplified_txns
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
