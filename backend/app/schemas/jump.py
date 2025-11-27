"""Jump schemas"""
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List
from app.models.jump import JumpType

class JumpBase(BaseModel):
    date: datetime
    location: str = Field(..., min_length=1)
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    altitude: int = Field(..., gt=0)
    jump_type: Optional[JumpType] = None
    equipment_ids: List[str] = []
    checklist_completed: bool = False
    notes: Optional[str] = None

class JumpCreate(JumpBase):
    pass

class JumpUpdate(BaseModel):
    date: Optional[datetime] = None
    location: Optional[str] = Field(None, min_length=1)
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    altitude: Optional[int] = Field(None, gt=0)
    jump_type: Optional[JumpType] = None
    equipment_ids: Optional[List[str]] = None
    checklist_completed: Optional[bool] = None
    notes: Optional[str] = None

class JumpResponse(JumpBase):
    id: str
    created_at: datetime

    model_config = {"from_attributes": True}
