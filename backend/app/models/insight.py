from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.core.database import Base

class Insight(Base):
    __tablename__ = "insights"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    type = Column(String, nullable=False) # e.g. subscription, bill
    confidence_score = Column(Float, nullable=True)
    potential_savings = Column(Float, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
