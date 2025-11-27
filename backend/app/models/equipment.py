"""Equipment database model"""
from sqlalchemy import Column, String, DateTime, Enum
from sqlalchemy.sql import func
from app.db.database import Base
import uuid
import enum

class EquipmentType(str, enum.Enum):
    PARACHUTE = "parachute"
    HARNESS = "harness"
    RESERVE = "reserve"
    ALTIMETER = "altimeter"
    HELMET = "helmet"
    GOGGLES = "goggles"
    OTHER = "other"

class Equipment(Base):
    __tablename__ = "equipment"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False)
    type = Column(Enum(EquipmentType), nullable=False)
    manufacturer = Column(String, nullable=True)
    model = Column(String, nullable=True)
    serial_number = Column(String, nullable=True)
    purchase_date = Column(DateTime(timezone=True), nullable=True)
    reminder_after_jumps = Column(Integer, nullable=True)  # For reserve parachute: remind after X jumps
    notes = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
