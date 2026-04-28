from sqlalchemy import Column, Integer, String, ForeignKey
from app.core.database import Base

class BankAccount(Base):
    __tablename__ = "bank_accounts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    plaid_access_token = Column(String, nullable=False)
    institution_name = Column(String, nullable=True)
