"""Jump service for business logic"""
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func
from typing import List, Optional
from app.models.jump import Jump
from app.models.equipment import Equipment
from app.models.profile import Profile
from app.schemas.jump import JumpCreate, JumpUpdate
from app.core.logging_config import get_logger

logger = get_logger(__name__)

class JumpService:
    @staticmethod
    def get_all(db: Session) -> List[Jump]:
        """Get all jumps"""
        logger.info("Fetching all jumps", extra={"event": "jump_get_all"})
        jumps = db.query(Jump).options(joinedload(Jump.equipment)).order_by(Jump.date.desc()).all()
        logger.info("Retrieved jumps", extra={"event": "jump_get_all_success", "count": len(jumps)})
        return jumps

    @staticmethod
    def get_by_id(db: Session, jump_id: str) -> Optional[Jump]:
        """Get jump by ID"""
        return db.query(Jump).options(joinedload(Jump.equipment)).filter(Jump.id == jump_id).first()

    @staticmethod
    def create(db: Session, jump_data: JumpCreate) -> Jump:
        """Create a new jump"""
        logger.info(
            "Creating jump",
            extra={
                "event": "jump_create",
                "location": jump_data.location,
                "altitude": jump_data.altitude,
            }
        )
        jump = Jump(
            date=jump_data.date,
            location=jump_data.location,
            latitude=jump_data.latitude,
            longitude=jump_data.longitude,
            altitude=jump_data.altitude,
            jump_type=jump_data.jump_type,
            jump_method=jump_data.jump_method,
            # checklist_completed is deprecated and ignored - always defaults to False
            notes=jump_data.notes,
        )
        
        # Set freefall stats if provided
        if jump_data.freefall_stats:
            jump.freefall_duration_seconds = jump_data.freefall_stats.freefall_duration_seconds
            jump.max_vertical_velocity_ms = jump_data.freefall_stats.max_vertical_velocity_ms
            jump.exit_time = jump_data.freefall_stats.exit_time
            jump.deployment_time = jump_data.freefall_stats.deployment_time
            logger.info(
                "Freefall stats set on jump",
                extra={
                    "jump_id": jump.id,
                    "duration": jump.freefall_duration_seconds,
                    "max_velocity": jump.max_vertical_velocity_ms,
                }
            )
        
        # Set weather data if provided
        if jump_data.weather:
            jump.weather_temperature_celsius = jump_data.weather.temperature_celsius
            jump.weather_wind_speed_kmh = jump_data.weather.wind_speed_kmh
            jump.weather_wind_direction_degrees = jump_data.weather.wind_direction_degrees
            jump.weather_wind_gusts_kmh = jump_data.weather.wind_gusts_kmh
            jump.weather_code = jump_data.weather.weather_code
            jump.weather_description = jump_data.weather.weather_description
            jump.weather_humidity_percent = jump_data.weather.humidity_percent
            jump.weather_pressure_hpa = jump_data.weather.pressure_hpa
            jump.weather_cloud_cover_percent = jump_data.weather.cloud_cover_percent
            jump.weather_visibility_km = jump_data.weather.visibility_km
            logger.info(
                "Weather data set on jump",
                extra={
                    "jump_id": jump.id,
                    "temperature": jump.weather_temperature_celsius,
                    "wind_speed": jump.weather_wind_speed_kmh,
                    "wind_direction": jump.weather_wind_direction_degrees,
                }
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
        # Ensure equipment relationship is loaded
        _ = jump.equipment  # Trigger lazy load if needed
        
        # Update profile total jumps count
        profile = db.query(Profile).first()
        if profile:
            total_jumps = db.query(func.count(Jump.id)).scalar() or 0
            profile.total_jumps = total_jumps
            db.commit()
            db.refresh(profile)
            logger.info("Profile total jumps updated", extra={"event": "profile_update_total_jumps", "total_jumps": total_jumps})
        
        logger.info("Jump created successfully", extra={"event": "jump_create_success", "jump_id": jump.id})
        return jump

    @staticmethod
    def update(db: Session, jump_id: str, jump_update: JumpUpdate) -> Optional[Jump]:
        """Update a jump"""
        jump = db.query(Jump).options(joinedload(Jump.equipment)).filter(Jump.id == jump_id).first()
        if not jump:
            return None
        
        update_data = jump_update.model_dump(exclude_unset=True)
        
        # Remove deprecated fields that should not be updated
        update_data.pop("checklist_completed", None)  # Deprecated - always ignore
        
        # Handle freefall_stats update separately
        if "freefall_stats" in update_data:
            freefall_stats = update_data.pop("freefall_stats")
            if freefall_stats and isinstance(freefall_stats, dict):
                # Update freefall stats fields
                jump.freefall_duration_seconds = freefall_stats.get("freefall_duration_seconds")
                jump.max_vertical_velocity_ms = freefall_stats.get("max_vertical_velocity_ms")
                # Handle datetime strings
                exit_time = freefall_stats.get("exit_time")
                if exit_time:
                    if isinstance(exit_time, str):
                        from datetime import datetime
                        jump.exit_time = datetime.fromisoformat(exit_time.replace('Z', '+00:00'))
                    else:
                        jump.exit_time = exit_time
                deployment_time = freefall_stats.get("deployment_time")
                if deployment_time:
                    if isinstance(deployment_time, str):
                        from datetime import datetime
                        jump.deployment_time = datetime.fromisoformat(deployment_time.replace('Z', '+00:00'))
                    else:
                        jump.deployment_time = deployment_time
            elif freefall_stats is None:
                # Explicitly clear freefall stats if None is provided
                jump.freefall_duration_seconds = None
                jump.max_vertical_velocity_ms = None
                jump.exit_time = None
                jump.deployment_time = None
        
        # Handle weather update separately
        if "weather" in update_data:
            weather = update_data.pop("weather")
            if weather and isinstance(weather, dict):
                # Update weather fields
                jump.weather_temperature_celsius = weather.get("temperature_celsius")
                jump.weather_wind_speed_kmh = weather.get("wind_speed_kmh")
                jump.weather_wind_direction_degrees = weather.get("wind_direction_degrees")
                jump.weather_wind_gusts_kmh = weather.get("wind_gusts_kmh")
                jump.weather_code = weather.get("weather_code")
                jump.weather_description = weather.get("weather_description")
                jump.weather_humidity_percent = weather.get("humidity_percent")
                jump.weather_pressure_hpa = weather.get("pressure_hpa")
                jump.weather_cloud_cover_percent = weather.get("cloud_cover_percent")
                jump.weather_visibility_km = weather.get("visibility_km")
            elif weather is None:
                # Explicitly clear weather if None is provided
                jump.weather_temperature_celsius = None
                jump.weather_wind_speed_kmh = None
                jump.weather_wind_direction_degrees = None
                jump.weather_wind_gusts_kmh = None
                jump.weather_code = None
                jump.weather_description = None
                jump.weather_humidity_percent = None
                jump.weather_pressure_hpa = None
                jump.weather_cloud_cover_percent = None
                jump.weather_visibility_km = None
        
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
        # Ensure equipment relationship is loaded
        _ = jump.equipment  # Trigger lazy load if needed
        return jump

    @staticmethod
    def delete(db: Session, jump_id: str) -> bool:
        """Delete a jump"""
        logger.info("Deleting jump", extra={"event": "jump_delete", "jump_id": jump_id})
        jump = db.query(Jump).filter(Jump.id == jump_id).first()
        if not jump:
            logger.warning("Jump not found for deletion", extra={"event": "jump_delete_not_found", "jump_id": jump_id})
            return False
        db.delete(jump)
        db.commit()
        
        # Update profile total jumps count
        profile = db.query(Profile).first()
        if profile:
            total_jumps = db.query(func.count(Jump.id)).scalar() or 0
            profile.total_jumps = total_jumps
            db.commit()
            db.refresh(profile)
            logger.info("Profile total jumps updated", extra={"event": "profile_update_total_jumps", "total_jumps": total_jumps})
        
        logger.info("Jump deleted successfully", extra={"event": "jump_delete_success", "jump_id": jump_id})
        return True
