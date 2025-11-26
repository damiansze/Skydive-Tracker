"""Equipment API endpoints"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.db.database import get_db
from app.schemas.equipment import EquipmentCreate, EquipmentUpdate, EquipmentResponse
from app.services.equipment_service import EquipmentService

router = APIRouter()

@router.get("/", response_model=List[EquipmentResponse])
async def get_equipment(db: Session = Depends(get_db)):
    """Get all equipment"""
    return EquipmentService.get_all(db)

@router.get("/{equipment_id}", response_model=EquipmentResponse)
async def get_equipment_item(equipment_id: str, db: Session = Depends(get_db)):
    """Get a specific equipment item by ID"""
    equipment = EquipmentService.get_by_id(db, equipment_id)
    if not equipment:
        raise HTTPException(status_code=404, detail="Equipment not found")
    return equipment

@router.post("/", response_model=EquipmentResponse, status_code=201)
async def create_equipment(equipment: EquipmentCreate, db: Session = Depends(get_db)):
    """Create a new equipment item"""
    return EquipmentService.create(db, equipment)

@router.put("/{equipment_id}", response_model=EquipmentResponse)
async def update_equipment(
    equipment_id: str,
    equipment_update: EquipmentUpdate,
    db: Session = Depends(get_db),
):
    """Update an equipment item"""
    equipment = EquipmentService.update(db, equipment_id, equipment_update)
    if not equipment:
        raise HTTPException(status_code=404, detail="Equipment not found")
    return equipment

@router.delete("/{equipment_id}", status_code=204)
async def delete_equipment(equipment_id: str, db: Session = Depends(get_db)):
    """Delete an equipment item"""
    success = EquipmentService.delete(db, equipment_id)
    if not success:
        raise HTTPException(status_code=404, detail="Equipment not found")
