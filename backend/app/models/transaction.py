from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Boolean
from sqlalchemy.sql import func
from app.core.database import Base

class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    plaid_transaction_id = Column(String, unique=True, index=True)
    amount = Column(Float, nullable=False)
    currency = Column(String, default="USD")
    name = Column(String, nullable=False)
    merchant_name = Column(String, nullable=True)
    date = Column(DateTime(timezone=True), nullable=False)
    
    # Intelligence Engine Flags
    is_subscription = Column(Boolean, default=False)
    is_duplicate = Column(Boolean, default=False)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
