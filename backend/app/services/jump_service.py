"""Jump service for business logic"""
from sqlalchemy.orm import Session
from typing import List, Optional
from app.models.jump import Jump
from app.models.equipment import Equipment
from app.schemas.jump import JumpCreate, JumpUpdate

class JumpService:
    @staticmethod
    def get_all(db: Session) -> List[Jump]:
        """Get all jumps"""
        return db.query(Jump).order_by(Jump.date.desc()).all()

    @staticmethod
    def get_by_id(db: Session, jump_id: str) -> Optional[Jump]:
        """Get jump by ID"""
        return db.query(Jump).filter(Jump.id == jump_id).first()

    @staticmethod
    def create(db: Session, jump_data: JumpCreate) -> Jump:
        """Create a new jump"""
        jump = Jump(
            date=jump_data.date,
            location=jump_data.location,
            altitude=jump_data.altitude,
            checklist_completed=jump_data.checklist_completed,
            notes=jump_data.notes,
        )
        
        # Add equipment associations
        if jump_data.equipment_ids:
            equipment_items = db.query(Equipment).filter(
                Equipment.id.in_(jump_data.equipment_ids)
            ).all()
            jump.equipment = equipment_items
        
        db.add(jump)
        db.commit()
        db.refresh(jump)
        return jump

    @staticmethod
    def update(db: Session, jump_id: str, jump_update: JumpUpdate) -> Optional[Jump]:
        """Update a jump"""
        jump = db.query(Jump).filter(Jump.id == jump_id).first()
        if not jump:
            return None
        
        update_data = jump_update.dict(exclude_unset=True)
        
        # Handle equipment update separately
        if "equipment_ids" in update_data:
            equipment_ids = update_data.pop("equipment_ids")
            equipment_items = db.query(Equipment).filter(
                Equipment.id.in_(equipment_ids)
            ).all()
            jump.equipment = equipment_items
        
        for field, value in update_data.items():
            setattr(jump, field, value)
        
        db.commit()
        db.refresh(jump)
        return jump

    @staticmethod
    def delete(db: Session, jump_id: str) -> bool:
        """Delete a jump"""
        jump = db.query(Jump).filter(Jump.id == jump_id).first()
        if not jump:
            return False
        db.delete(jump)
        db.commit()
        return True
