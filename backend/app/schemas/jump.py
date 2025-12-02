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
        "from_attributes": False,  # Disable automatic from_attributes to use custom model_validate
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
            # Check if ANY freefall field exists, not just if all exist
            freefall_data = {}
            has_any_freefall_data = False
            
            # Debug: Check what attributes exist
            import logging
            logger = logging.getLogger(__name__)
            logger.info(f"JumpResponse.model_validate - obj attributes: {dir(obj)}")
            logger.info(f"JumpResponse.model_validate - freefall_duration_seconds: {getattr(obj, 'freefall_duration_seconds', 'NOT_FOUND')}")
            logger.info(f"JumpResponse.model_validate - max_vertical_velocity_ms: {getattr(obj, 'max_vertical_velocity_ms', 'NOT_FOUND')}")
            
            if hasattr(obj, 'freefall_duration_seconds') and obj.freefall_duration_seconds is not None:
                freefall_data['freefall_duration_seconds'] = obj.freefall_duration_seconds
                has_any_freefall_data = True
            if hasattr(obj, 'max_vertical_velocity_ms') and obj.max_vertical_velocity_ms is not None:
                freefall_data['max_vertical_velocity_ms'] = obj.max_vertical_velocity_ms
                has_any_freefall_data = True
            if hasattr(obj, 'exit_time') and obj.exit_time is not None:
                freefall_data['exit_time'] = obj.exit_time.isoformat() if isinstance(obj.exit_time, datetime) else obj.exit_time
                has_any_freefall_data = True
            if hasattr(obj, 'deployment_time') and obj.deployment_time is not None:
                freefall_data['deployment_time'] = obj.deployment_time.isoformat() if isinstance(obj.deployment_time, datetime) else obj.deployment_time
                has_any_freefall_data = True
            
            logger.info(f"JumpResponse.model_validate - freefall_data: {freefall_data}, has_any: {has_any_freefall_data}")
            
            # Always include freefall_stats if any data exists, even if empty dict
            if has_any_freefall_data:
                data['freefall_stats'] = freefall_data
            else:
                # Explicitly set to None if no data exists
                data['freefall_stats'] = None
            
            # Use model_validate with the prepared data dict
            return super().model_validate(data, **kwargs)
        # If obj is not a model instance, try normal validation
        # This handles dict inputs
        if isinstance(obj, dict):
            # If it's already a dict, check if freefall_stats needs formatting
            if 'freefall_stats' not in obj or obj['freefall_stats'] is None:
                # Try to reconstruct from individual fields
                freefall_data = {}
                if obj.get('freefall_duration_seconds') is not None:
                    freefall_data['freefall_duration_seconds'] = obj['freefall_duration_seconds']
                if obj.get('max_vertical_velocity_ms') is not None:
                    freefall_data['max_vertical_velocity_ms'] = obj['max_vertical_velocity_ms']
                if obj.get('exit_time') is not None:
                    freefall_data['exit_time'] = obj['exit_time']
                if obj.get('deployment_time') is not None:
                    freefall_data['deployment_time'] = obj['deployment_time']
                if freefall_data:
                    obj['freefall_stats'] = freefall_data
        return super().model_validate(obj, **kwargs)
    
    def model_dump(self, **kwargs):
        """Override model_dump to exclude checklist_completed and ensure freefall_stats is formatted"""
        data = super().model_dump(**kwargs)
        # Remove checklist_completed if it somehow got included
        data.pop("checklist_completed", None)
        
        # Ensure freefall_stats is properly formatted
        # If freefall_stats is already in data and is a dict, keep it
        # Otherwise, try to reconstruct from model attributes
        if "freefall_stats" not in data or data["freefall_stats"] is None:
            # Try to get from model attributes if this is a model instance
            if hasattr(self, '__dict__'):
                model_dict = self.__dict__
                freefall_data = {}
                has_any_data = False
                
                if 'freefall_duration_seconds' in model_dict and model_dict['freefall_duration_seconds'] is not None:
                    freefall_data['freefall_duration_seconds'] = model_dict['freefall_duration_seconds']
                    has_any_data = True
                if 'max_vertical_velocity_ms' in model_dict and model_dict['max_vertical_velocity_ms'] is not None:
                    freefall_data['max_vertical_velocity_ms'] = model_dict['max_vertical_velocity_ms']
                    has_any_data = True
                if 'exit_time' in model_dict and model_dict['exit_time'] is not None:
                    exit_time = model_dict['exit_time']
                    freefall_data['exit_time'] = exit_time.isoformat() if isinstance(exit_time, datetime) else exit_time
                    has_any_data = True
                if 'deployment_time' in model_dict and model_dict['deployment_time'] is not None:
                    deployment_time = model_dict['deployment_time']
                    freefall_data['deployment_time'] = deployment_time.isoformat() if isinstance(deployment_time, datetime) else deployment_time
                    has_any_data = True
                
                if has_any_data:
                    data['freefall_stats'] = freefall_data
                else:
                    data['freefall_stats'] = None
        
        return data
