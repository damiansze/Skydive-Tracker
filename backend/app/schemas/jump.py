"""Jump schemas"""
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List
from app.models.jump import JumpType, JumpMethod

class FreefallStatsBase(BaseModel):
    freefall_duration_seconds: Optional[float] = None
    max_vertical_velocity_ms: Optional[float] = None
    exit_time: Optional[datetime] = None
    deployment_time: Optional[datetime] = None

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
    freefall_stats: Optional[FreefallStatsBase] = None
    
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
    freefall_stats: Optional[FreefallStatsBase] = None
    
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
        """Override model_dump to exclude checklist_completed and format freefall_stats"""
        data = super().model_dump(**kwargs)
        # Remove checklist_completed if it somehow got included
        data.pop("checklist_completed", None)
        
        # Format freefall_stats from model attributes if not already in dict format
        if "freefall_stats" not in data or data["freefall_stats"] is None:
            # Try to get from model attributes
            if hasattr(self, '__dict__'):
                model_dict = self.__dict__
                if any(k.startswith('freefall_') or k in ['exit_time', 'deployment_time'] for k in model_dict.keys()):
                    freefall_data = {}
                    if hasattr(self, 'freefall_duration_seconds') and self.freefall_duration_seconds is not None:
                        freefall_data['freefall_duration_seconds'] = self.freefall_duration_seconds
                    if hasattr(self, 'max_vertical_velocity_ms') and self.max_vertical_velocity_ms is not None:
                        freefall_data['max_vertical_velocity_ms'] = self.max_vertical_velocity_ms
                    if hasattr(self, 'exit_time') and self.exit_time is not None:
                        freefall_data['exit_time'] = self.exit_time
                    if hasattr(self, 'deployment_time') and self.deployment_time is not None:
                        freefall_data['deployment_time'] = self.deployment_time
                    if freefall_data:
                        data['freefall_stats'] = freefall_data
        
        return data
    
    @classmethod
    def model_validate(cls, obj, **kwargs):
        """Override model_validate to exclude checklist_completed from model and format freefall_stats"""
        if hasattr(obj, '__dict__'):
            # If it's a model instance, create a dict excluding checklist_completed
            data = {k: v for k, v in obj.__dict__.items() if k != 'checklist_completed'}
            # Handle equipment_ids property
            if hasattr(obj, 'equipment_ids'):
                data['equipment_ids'] = obj.equipment_ids
            
            # Format freefall_stats from model attributes
            freefall_data = {}
            if hasattr(obj, 'freefall_duration_seconds') and obj.freefall_duration_seconds is not None:
                freefall_data['freefall_duration_seconds'] = obj.freefall_duration_seconds
            if hasattr(obj, 'max_vertical_velocity_ms') and obj.max_vertical_velocity_ms is not None:
                freefall_data['max_vertical_velocity_ms'] = obj.max_vertical_velocity_ms
            if hasattr(obj, 'exit_time') and obj.exit_time is not None:
                freefall_data['exit_time'] = obj.exit_time
            if hasattr(obj, 'deployment_time') and obj.deployment_time is not None:
                freefall_data['deployment_time'] = obj.deployment_time
            
            if freefall_data:
                data['freefall_stats'] = freefall_data
            
            return super().model_validate(data, **kwargs)
        return super().model_validate(obj, **kwargs)
