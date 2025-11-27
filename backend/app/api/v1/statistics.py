"""Statistics API endpoints"""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import Optional
from app.db.database import get_db
from app.services.statistics_service import StatisticsService
from app.models.jump import JumpType, JumpMethod

router = APIRouter()

@router.get("/summary")
async def get_statistics_summary(
    location: Optional[str] = Query(None, description="Filter by location"),
    jump_type: Optional[str] = Query(None, description="Filter by jump type"),
    jump_method: Optional[str] = Query(None, description="Filter by jump method"),
    db: Session = Depends(get_db),
):
    """Get jump statistics summary"""
    return StatisticsService.get_summary(
        db, 
        location_filter=location,
        jump_type_filter=jump_type,
        jump_method_filter=jump_method,
    )

@router.get("/total-jumps")
async def get_total_jumps(
    location: Optional[str] = Query(None, description="Filter by location"),
    jump_type: Optional[str] = Query(None, description="Filter by jump type"),
    jump_method: Optional[str] = Query(None, description="Filter by jump method"),
    db: Session = Depends(get_db),
):
    """Get total number of jumps"""
    return {"total_jumps": StatisticsService.get_total_jumps(
        db, 
        location_filter=location,
        jump_type_filter=jump_type,
        jump_method_filter=jump_method,
    )}
