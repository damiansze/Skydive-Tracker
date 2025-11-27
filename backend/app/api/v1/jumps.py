"""Jump API endpoints"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.db.database import get_db
from app.schemas.jump import JumpCreate, JumpUpdate, JumpResponse
from app.services.jump_service import JumpService
from app.core.logging_config import get_logger

logger = get_logger(__name__)
router = APIRouter()

@router.get("/", response_model=List[JumpResponse])
async def get_jumps(db: Session = Depends(get_db)):
    """Get all jumps"""
    try:
        return JumpService.get_all(db)
    except Exception as e:
        logger.error(f"Error fetching jumps: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to fetch jumps: {str(e)}")

@router.get("/{jump_id}", response_model=JumpResponse)
async def get_jump(jump_id: str, db: Session = Depends(get_db)):
    """Get a specific jump by ID"""
    jump = JumpService.get_by_id(db, jump_id)
    if not jump:
        raise HTTPException(status_code=404, detail="Jump not found")
    return jump

@router.post("/", response_model=JumpResponse, status_code=201)
async def create_jump(jump: JumpCreate, db: Session = Depends(get_db)):
    """Create a new jump"""
    try:
        return JumpService.create(db, jump)
    except Exception as e:
        logger.error(f"Error creating jump: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to create jump: {str(e)}")

@router.put("/{jump_id}", response_model=JumpResponse)
async def update_jump(jump_id: str, jump_update: JumpUpdate, db: Session = Depends(get_db)):
    """Update a jump"""
    jump = JumpService.update(db, jump_id, jump_update)
    if not jump:
        raise HTTPException(status_code=404, detail="Jump not found")
    return jump

@router.delete("/{jump_id}", status_code=204)
async def delete_jump(jump_id: str, db: Session = Depends(get_db)):
    """Delete a jump"""
    success = JumpService.delete(db, jump_id)
    if not success:
        raise HTTPException(status_code=404, detail="Jump not found")
