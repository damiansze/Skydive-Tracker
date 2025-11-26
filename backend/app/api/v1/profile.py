"""Profile API endpoints"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.schemas.profile import ProfileBase, ProfileUpdate, ProfileResponse
from app.services.profile_service import ProfileService

router = APIRouter()

@router.get("/", response_model=ProfileResponse)
async def get_profile(db: Session = Depends(get_db)):
    """Get user profile"""
    profile = ProfileService.get_profile(db)
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    return profile

@router.post("/", response_model=ProfileResponse, status_code=201)
async def create_profile(profile_data: ProfileBase, db: Session = Depends(get_db)):
    """Create or update user profile"""
    return ProfileService.create_or_update(db, profile_data)

@router.put("/", response_model=ProfileResponse)
async def update_profile(profile_update: ProfileUpdate, db: Session = Depends(get_db)):
    """Update user profile"""
    profile = ProfileService.update(db, profile_update)
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    return profile
