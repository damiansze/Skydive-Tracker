"""Profile schemas"""
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional

class ProfileBase(BaseModel):
    name: str = Field(..., min_length=1)
    license_number: Optional[str] = None
    license_type: Optional[str] = None

class ProfileUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1)
    license_number: Optional[str] = None
    license_type: Optional[str] = None

class ProfileResponse(ProfileBase):
    id: str
    total_jumps: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
