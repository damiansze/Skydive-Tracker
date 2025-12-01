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
                freefall_data['exit_time'] = obj.exit_time.isoformat() if isinstance(obj.exit_time, datetime) else obj.exit_time
            if hasattr(obj, 'deployment_time') and obj.deployment_time is not None:
                freefall_data['deployment_time'] = obj.deployment_time.isoformat() if isinstance(obj.deployment_time, datetime) else obj.deployment_time
            
            if freefall_data:
                data['freefall_stats'] = freefall_data
            
            return super().model_validate(data, **kwargs)
        return super().model_validate(obj, **kwargs)
    
    def model_dump(self, **kwargs):
        """Override model_dump to exclude checklist_completed and ensure freefall_stats is formatted"""
        data = super().model_dump(**kwargs)
        # Remove checklist_completed if it somehow got included
        data.pop("checklist_completed", None)
        
        # Ensure freefall_stats is properly formatted
        if "freefall_stats" not in data or data["freefall_stats"] is None:
            # Try to get from model attributes if this is a model instance
            if hasattr(self, '__dict__'):
                model_dict = self.__dict__
                freefall_data = {}
                if 'freefall_duration_seconds' in model_dict and model_dict['freefall_duration_seconds'] is not None:
                    freefall_data['freefall_duration_seconds'] = model_dict['freefall_duration_seconds']
                if 'max_vertical_velocity_ms' in model_dict and model_dict['max_vertical_velocity_ms'] is not None:
                    freefall_data['max_vertical_velocity_ms'] = model_dict['max_vertical_velocity_ms']
                if 'exit_time' in model_dict and model_dict['exit_time'] is not None:
                    exit_time = model_dict['exit_time']
                    freefall_data['exit_time'] = exit_time.isoformat() if isinstance(exit_time, datetime) else exit_time
                if 'deployment_time' in model_dict and model_dict['deployment_time'] is not None:
                    deployment_time = model_dict['deployment_time']
                    freefall_data['deployment_time'] = deployment_time.isoformat() if isinstance(deployment_time, datetime) else deployment_time
                if freefall_data:
                    data['freefall_stats'] = freefall_data
        
        return data
