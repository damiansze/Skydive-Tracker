"""Profile service for business logic"""
from sqlalchemy.orm import Session
from typing import Optional
from app.models.profile import Profile
from app.schemas.profile import ProfileBase, ProfileUpdate
from app.core.logging_config import get_logger

logger = get_logger(__name__)

class ProfileService:
    @staticmethod
    def get_profile(db: Session) -> Optional[Profile]:
        """Get user profile (assuming single user for now)"""
        return db.query(Profile).first()

    @staticmethod
    def create_or_update(db: Session, profile_data: ProfileBase) -> Profile:
        """Create or update user profile"""
        profile = db.query(Profile).first()
        
        if profile:
            # Update existing profile
            profile.name = profile_data.name
            profile.license_number = profile_data.license_number
            profile.license_type = profile_data.license_type
        else:
            # Create new profile
            profile = Profile(**profile_data.dict())
            db.add(profile)
        
        db.commit()
        db.refresh(profile)
        return profile

    @staticmethod
    def update(db: Session, profile_update: ProfileUpdate) -> Optional[Profile]:
        """Update user profile"""
        profile = db.query(Profile).first()
        if not profile:
            return None
        
        update_data = profile_update.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(profile, field, value)
        
        db.commit()
        db.refresh(profile)
        return profile
