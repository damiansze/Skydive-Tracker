"""Jump database model"""
from sqlalchemy import Column, String, Integer, Boolean, DateTime, ForeignKey, Table
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.database import Base
import uuid

# Association table for many-to-many relationship between jumps and equipment
jump_equipment = Table(
    "jump_equipment",
    Base.metadata,
    Column("jump_id", String, ForeignKey("jumps.id", ondelete="CASCADE"), primary_key=True),
    Column("equipment_id", String, ForeignKey("equipment.id", ondelete="CASCADE"), primary_key=True),
)

class Jump(Base):
    __tablename__ = "jumps"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    date = Column(DateTime(timezone=True), nullable=False)
    location = Column(String, nullable=False)
    altitude = Column(Integer, nullable=False)  # in feet or meters
    checklist_completed = Column(Boolean, default=False)
    notes = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    equipment = relationship("Equipment", secondary=jump_equipment, backref="jumps")
