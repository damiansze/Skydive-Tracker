"""Equipment service for business logic"""
from sqlalchemy.orm import Session
from typing import List, Optional
from app.models.equipment import Equipment
from app.schemas.equipment import EquipmentCreate, EquipmentUpdate
from app.core.logging_config import get_logger

logger = get_logger(__name__)

class EquipmentService:
    @staticmethod
    def get_all(db: Session) -> List[Equipment]:
        """Get all equipment"""
        return db.query(Equipment).all()

    @staticmethod
    def get_by_id(db: Session, equipment_id: str) -> Optional[Equipment]:
        """Get equipment by ID"""
        return db.query(Equipment).filter(Equipment.id == equipment_id).first()

    @staticmethod
    def create(db: Session, equipment_data: EquipmentCreate) -> Equipment:
        """Create a new equipment item"""
        equipment = Equipment(**equipment_data.model_dump())
        db.add(equipment)
        db.commit()
        db.refresh(equipment)
        return equipment

    @staticmethod
    def update(db: Session, equipment_id: str, equipment_update: EquipmentUpdate) -> Optional[Equipment]:
        """Update an equipment item"""
        equipment = db.query(Equipment).filter(Equipment.id == equipment_id).first()
        if not equipment:
            return None
        
        update_data = equipment_update.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(equipment, field, value)
        
        db.commit()
        db.refresh(equipment)
        return equipment

    @staticmethod
    def delete(db: Session, equipment_id: str) -> bool:
        """Delete an equipment item"""
        equipment = db.query(Equipment).filter(Equipment.id == equipment_id).first()
        if not equipment:
            return False
        db.delete(equipment)
        db.commit()
        return True
