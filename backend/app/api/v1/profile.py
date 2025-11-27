"""Profile API endpoints"""
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.schemas.profile import ProfileBase, ProfileUpdate, ProfileResponse
from app.services.profile_service import ProfileService
from app.core.logging_config import get_logger
import os
import uuid
from pathlib import Path

logger = get_logger(__name__)
router = APIRouter()

# Create uploads directory if it doesn't exist
UPLOAD_DIR = Path("uploads/profile_pictures")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

@router.get("/", response_model=ProfileResponse)
async def get_profile(db: Session = Depends(get_db)):
    """Get user profile"""
    try:
        profile = ProfileService.get_profile(db)
        if not profile:
            raise HTTPException(status_code=404, detail="Profile not found")
        return profile
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching profile: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to fetch profile: {str(e)}")

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

@router.post("/upload-picture")
async def upload_profile_picture(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    """Upload profile picture"""
    try:
        # Validate file type - check both content_type and filename extension
        valid_extensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp']
        file_extension = Path(file.filename).suffix.lower() if file.filename else ''
        
        is_valid_image = (
            (file.content_type and file.content_type.startswith('image/')) or
            file_extension in valid_extensions
        )
        
        if not is_valid_image:
            raise HTTPException(
                status_code=400, 
                detail=f"File must be an image. Received: content_type={file.content_type}, filename={file.filename}"
            )
        
        # Generate unique filename
        file_extension = Path(file.filename).suffix if file.filename else '.jpg'
        unique_filename = f"{uuid.uuid4()}{file_extension}"
        file_path = UPLOAD_DIR / unique_filename
        
        # Save file
        with open(file_path, "wb") as buffer:
            content = await file.read()
            buffer.write(content)
        
        # Update profile with picture URL
        profile = ProfileService.get_profile(db)
        if not profile:
            # Delete uploaded file if no profile exists
            file_path.unlink()
            raise HTTPException(status_code=404, detail="Profile not found")
        
        # Delete old picture if exists
        if profile.profile_picture_url:
            old_path = Path(profile.profile_picture_url.replace('/api/v1/profile/picture/', ''))
            old_file = UPLOAD_DIR / old_path.name
            if old_file.exists():
                old_file.unlink()
        
        # Update profile with new picture URL
        picture_url = f"/api/v1/profile/picture/{unique_filename}"
        profile.profile_picture_url = picture_url
        db.commit()
        db.refresh(profile)
        
        logger.info(f"Profile picture uploaded: {picture_url}")
        return {"profile_picture_url": picture_url}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error uploading profile picture: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to upload picture: {str(e)}")

@router.get("/picture/{filename}")
async def get_profile_picture(filename: str):
    """Get profile picture"""
    file_path = UPLOAD_DIR / filename
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="Picture not found")
    return FileResponse(file_path)
