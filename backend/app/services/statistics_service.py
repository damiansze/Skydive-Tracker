"""Statistics service for business logic"""
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models.jump import Jump
from typing import Optional, Dict, Any

class StatisticsService:
    @staticmethod
    def get_total_jumps(db: Session, location_filter: Optional[str] = None) -> int:
        """Get total number of jumps, optionally filtered by location"""
        query = db.query(func.count(Jump.id))
        
        if location_filter:
            query = query.filter(Jump.location.ilike(f"%{location_filter}%"))
        
        return query.scalar() or 0

    @staticmethod
    def get_summary(db: Session, location_filter: Optional[str] = None) -> Dict[str, Any]:
        """Get statistics summary"""
        query = db.query(Jump)
        
        if location_filter:
            query = query.filter(Jump.location.ilike(f"%{location_filter}%"))
        
        total_jumps = query.count()
        avg_altitude = db.query(func.avg(Jump.altitude)).scalar() or 0
        
        # Get unique locations
        locations = db.query(Jump.location).distinct().all()
        unique_locations = [loc[0] for loc in locations]
        
        return {
            "total_jumps": total_jumps,
            "average_altitude": round(float(avg_altitude), 2),
            "unique_locations": len(unique_locations),
            "locations": unique_locations,
        }
