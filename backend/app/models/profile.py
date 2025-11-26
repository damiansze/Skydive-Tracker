"""Profile database model"""
from sqlalchemy import Column, String, Integer, DateTime
from sqlalchemy.sql import func
from app.db.database import Base
import uuid

class Profile(Base):
    __tablename__ = "profiles"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False)
    license_number = Column(String, nullable=True)
    license_type = Column(String, nullable=True)
    total_jumps = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
