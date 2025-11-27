"""Statistics service for business logic"""
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models.jump import Jump, JumpType, JumpMethod
from typing import Optional, Dict, Any
from collections import Counter

class StatisticsService:
    @staticmethod
    def get_total_jumps(
        db: Session, 
        location_filter: Optional[str] = None,
        jump_type_filter: Optional[str] = None,
        jump_method_filter: Optional[str] = None,
    ) -> int:
        """Get total number of jumps, optionally filtered"""
        query = db.query(func.count(Jump.id))
        
        if location_filter:
            query = query.filter(Jump.location.ilike(f"%{location_filter}%"))
        
        if jump_type_filter:
            try:
                jump_type_enum = JumpType(jump_type_filter.lower())
                query = query.filter(Jump.jump_type == jump_type_enum)
            except ValueError:
                pass
        
        if jump_method_filter:
            try:
                jump_method_enum = JumpMethod(jump_method_filter.lower())
                query = query.filter(Jump.jump_method == jump_method_enum)
            except ValueError:
                pass
        
        return query.scalar() or 0

    @staticmethod
    def get_summary(
        db: Session, 
        location_filter: Optional[str] = None,
        jump_type_filter: Optional[str] = None,
        jump_method_filter: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Get statistics summary"""
        query = db.query(Jump)
        
        if location_filter:
            query = query.filter(Jump.location.ilike(f"%{location_filter}%"))
        
        if jump_type_filter:
            try:
                jump_type_enum = JumpType(jump_type_filter.lower())
                query = query.filter(Jump.jump_type == jump_type_enum)
            except ValueError:
                pass
        
        if jump_method_filter:
            try:
                jump_method_enum = JumpMethod(jump_method_filter.lower())
                query = query.filter(Jump.jump_method == jump_method_enum)
            except ValueError:
                pass
        
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
        
        # Get locations with coordinates for map - group by coordinates and count
        from collections import defaultdict
        location_groups = defaultdict(list)
        for jump in jumps:
            if jump.latitude is not None and jump.longitude is not None:
                # Round coordinates to 4 decimal places (~11 meters precision) to group nearby jumps
                key = (round(jump.latitude, 4), round(jump.longitude, 4))
                location_groups[key].append(jump)
        
        locations_with_coords = []
        for (lat, lng), jump_list in location_groups.items():
            # Use average coordinates for the group
            avg_lat = sum(j.latitude for j in jump_list) / len(jump_list)
            avg_lng = sum(j.longitude for j in jump_list) / len(jump_list)
            locations_with_coords.append({
                "location": jump_list[0].location,
                "latitude": avg_lat,
                "longitude": avg_lng,
                "count": len(jump_list),  # Number of jumps at this location
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
