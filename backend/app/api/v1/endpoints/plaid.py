from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session
from datetime import date, timedelta
from app.services import plaid_service
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.bank_account import BankAccount
from app.models.transaction import Transaction
from app.models.insight import Insight
from app.core.encryption import encrypt, decrypt

router = APIRouter()

class ExchangeRequest(BaseModel):
    public_token: str
    institution_name: str = "Unknown"

@router.post("/create-link-token")
async def create_link_token_endpoint(current_user: User = Depends(get_current_user)):
    try:
        link_token = plaid_service.create_link_token(str(current_user.id))
        return {"link_token": link_token}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/exchange-token")
async def exchange_token_endpoint(
    req: ExchangeRequest, 
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        # Exchange token via Plaid API
        exchange_response = plaid_service.exchange_public_token(req.public_token)
        
        encrypted_token = encrypt(exchange_response['access_token'])
        
        # Securely store the access_token in the database
        bank_account = BankAccount(
            user_id=current_user.id,
            plaid_access_token=encrypted_token,
            institution_name=req.institution_name
        )
        db.add(bank_account)
        db.commit()
        
        return {"status": "connected"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Failed to exchange and connect bank account")

def _normalize_name(name: str) -> str:
    name = name.lower()
    # Simple normalization for testing
    if "netflix" in name: return "Netflix"
    if "spotify" in name: return "Spotify"
    if "amazon" in name: return "Amazon"
    if "apple" in name: return "Apple"
    if "uber" in name: return "Uber"
    return name.title()

@router.post("/transactions/fetch")
async def fetch_transactions_endpoint(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        bank_accounts = db.query(BankAccount).filter(BankAccount.user_id == current_user.id).all()
        if not bank_accounts:
            raise HTTPException(status_code=400, detail="No bank account connected")
            
        end_date = date.today()
        start_date = end_date - timedelta(days=90)
        
        all_transactions = []
        
        for account in bank_accounts:
            access_token = decrypt(account.plaid_access_token)
            
            # Call Plaid
            transactions = plaid_service.fetch_transactions(
                access_token=access_token,
                start_date=start_date,
                end_date=end_date
            )
            
            for txn in transactions:
                # Basic Normalization
                merchant = txn.get('merchant_name') or txn.get('name')
                normalized = _normalize_name(merchant)
                
                # Simple subscription detection
                is_sub = normalized in ["Netflix", "Spotify", "Amazon Prime", "Apple"]
                
                new_txn = Transaction(
                    user_id=current_user.id,
                    amount=txn['amount'],
                    currency=txn['iso_currency_code'] or "USD",
                    merchant_name=merchant,
                    category=txn['category'][0] if txn.get('category') else "Unknown",
                    date=txn['date'],
                    normalized_name=normalized,
                    is_subscription=is_sub
                )
                db.add(new_txn)
                all_transactions.append(new_txn)
                
                if is_sub:
                    # check if insight already exists
                    existing_insight = db.query(Insight).filter(Insight.user_id == current_user.id, Insight.type == f"subscription_{normalized}").first()
                    if not existing_insight:
                        insight = Insight(
                            user_id=current_user.id,
                            type=f"subscription_{normalized}",
                            confidence_score=0.9,
                            potential_savings=txn['amount']
                        )
                        db.add(insight)
        
        db.commit()
        return {"status": "success", "fetched_count": len(all_transactions)}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/transactions")
async def get_transactions_endpoint(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        transactions = db.query(Transaction).filter(Transaction.user_id == current_user.id).order_by(Transaction.date.desc()).all()
        return {
            "status": "success",
            "transactions": [
                {
                    "id": str(txn.id),
                    "amount": txn.amount,
                    "currency": txn.currency,
                    "merchant": txn.merchant_name,
                    "merchantName": txn.normalized_name,
                    "category": txn.category,
                    "date": txn.date.isoformat(),
                    "isRecurring": txn.is_subscription
                } for txn in transactions
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
