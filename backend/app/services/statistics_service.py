"""Statistics service for business logic"""
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models.jump import Jump, JumpType, JumpMethod
from typing import Optional, Dict, Any
from collections import Counter

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
        
        jumps = query.all()
        total_jumps = len(jumps)
        avg_altitude = db.query(func.avg(Jump.altitude)).scalar() or 0
        
        # Get unique locations
        locations = db.query(Jump.location).distinct().all()
        unique_locations = [loc[0] for loc in locations]
        
        # Count jump types
        jump_types = [j.jump_type for j in jumps if j.jump_type is not None]
        jump_type_counts = {str(jt.value): count for jt, count in Counter(jump_types).items()}
        
        # Count jump methods
        jump_methods = [j.jump_method for j in jumps if j.jump_method is not None]
        jump_method_counts = {str(jm.value): count for jm, count in Counter(jump_methods).items()}
        
        # Get locations with coordinates for map
        locations_with_coords = []
        for jump in jumps:
            if jump.latitude is not None and jump.longitude is not None:
                locations_with_coords.append({
                    "location": jump.location,
                    "latitude": jump.latitude,
                    "longitude": jump.longitude,
                })
        
        return {
            "total_jumps": total_jumps,
            "average_altitude": round(float(avg_altitude), 2),
            "unique_locations": len(unique_locations),
            "locations": unique_locations,
            "jump_type_counts": jump_type_counts,
            "jump_method_counts": jump_method_counts,
            "locations_with_coords": locations_with_coords,
        }
