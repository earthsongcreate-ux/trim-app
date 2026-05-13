from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.core.database import Base


class UserProfile(Base):
    __tablename__ = "user_profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False, index=True)

    first_name = Column(String, nullable=True)
    monthly_income = Column(Integer, nullable=False, default=0)
    monthly_savings_goal = Column(Integer, nullable=False, default=0)
    onboarding_complete = Column(Boolean, nullable=False, default=False)

    is_premium = Column(Boolean, nullable=False, default=False)
    subscription_plan = Column(String, nullable=True)
    subscription_status = Column(String, nullable=True)
    trial_days = Column(Integer, nullable=True)
    trial_started_at = Column(DateTime(timezone=True), nullable=True)

    is_founding_member = Column(Boolean, nullable=False, default=False)
    founding_member_number = Column(Integer, nullable=True)
    locked_annual_price_cents = Column(Integer, nullable=True)
    locked_annual_price_currency = Column(String, nullable=True)
    has_early_supporter_badge = Column(Boolean, nullable=False, default=False)
    future_premium_features_included = Column(Boolean, nullable=False, default=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

