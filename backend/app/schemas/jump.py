"""Jump schemas"""
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List
from app.models.jump import JumpType, JumpMethod

class JumpBase(BaseModel):
    date: datetime
    location: str = Field(..., min_length=1)
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    altitude: int = Field(..., gt=0)
    jump_type: Optional[JumpType] = None
    jump_method: Optional[JumpMethod] = None
    equipment_ids: List[str] = []
    # checklist_completed removed - no longer used
    notes: Optional[str] = None
    
    class Config:
        # Ignore extra fields including deprecated checklist_completed
        extra = "ignore"

class JumpCreate(JumpBase):
    pass

class JumpUpdate(BaseModel):
    date: Optional[datetime] = None
    location: Optional[str] = Field(None, min_length=1)
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    altitude: Optional[int] = Field(None, gt=0)
    jump_type: Optional[JumpType] = None
    jump_method: Optional[JumpMethod] = None
    equipment_ids: Optional[List[str]] = None
    # checklist_completed removed - no longer used
    notes: Optional[str] = None
    
    class Config:
        # Ignore extra fields including deprecated checklist_completed
        extra = "ignore"

class JumpResponse(JumpBase):
    id: str
    created_at: datetime

    model_config = {
        "from_attributes": True,
        "populate_by_name": True,
    }
    
    def model_dump(self, **kwargs):
        """Override model_dump to exclude checklist_completed"""
        data = super().model_dump(**kwargs)
        # Remove checklist_completed if it somehow got included
        data.pop("checklist_completed", None)
        return data
    
    @classmethod
    def model_validate(cls, obj, **kwargs):
        """Override model_validate to exclude checklist_completed from model"""
        if hasattr(obj, '__dict__'):
            # If it's a model instance, create a dict excluding checklist_completed
            data = {k: v for k, v in obj.__dict__.items() if k != 'checklist_completed'}
            # Handle equipment_ids property
            if hasattr(obj, 'equipment_ids'):
                data['equipment_ids'] = obj.equipment_ids
            return super().model_validate(data, **kwargs)
        return super().model_validate(obj, **kwargs)
