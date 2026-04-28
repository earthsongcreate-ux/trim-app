from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Boolean
from app.core.database import Base

class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    amount = Column(Float, nullable=False)
    currency = Column(String, default="USD")
    merchant_name = Column(String, nullable=True)
    category = Column(String, nullable=True)
    date = Column(DateTime(timezone=True), nullable=False)
    normalized_name = Column(String, nullable=True)
    is_subscription = Column(Boolean, default=False)
