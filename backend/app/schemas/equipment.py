"""Equipment schemas"""
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional
from app.models.equipment import EquipmentType

class EquipmentBase(BaseModel):
    name: str = Field(..., min_length=1)
    type: EquipmentType
    manufacturer: Optional[str] = None
    model: Optional[str] = None
    serial_number: Optional[str] = None
    purchase_date: Optional[datetime] = None
    reminder_after_jumps: Optional[int] = Field(None, ge=0)  # For reserve: remind after X jumps
    notes: Optional[str] = None
    is_active: Optional[int] = Field(1, ge=0, le=1)  # 1 = active, 0 = inactive

class EquipmentCreate(EquipmentBase):
    pass

class EquipmentUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1)
    type: Optional[EquipmentType] = None
    manufacturer: Optional[str] = None
    model: Optional[str] = None
    serial_number: Optional[str] = None
    purchase_date: Optional[datetime] = None
    reminder_after_jumps: Optional[int] = Field(None, ge=0)
    notes: Optional[str] = None
    is_active: Optional[int] = Field(None, ge=0, le=1)

class EquipmentResponse(EquipmentBase):
    id: str
    created_at: datetime

    model_config = {"from_attributes": True}
