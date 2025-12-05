"""Jump database model"""
from sqlalchemy import Column, String, Integer, Boolean, DateTime, ForeignKey, Table, Float, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.database import Base
import uuid
import enum

class JumpType(str, enum.Enum):
    TANDEM = "tandem"
    SOLO = "solo"
    AFF = "aff"  # Accelerated Freefall
    STATIC_LINE = "static_line"
    WINGSUIT = "wingsuit"
    OTHER = "other"

class JumpMethod(str, enum.Enum):
    PLANE = "plane"
    HELICOPTER = "helicopter"
    BASE = "base"  # Base jumping (cliff, building, etc.)
    BALLOON = "balloon"
    OTHER = "other"

# Association table for many-to-many relationship between jumps and equipment
jump_equipment = Table(
    "jump_equipment",
    Base.metadata,
    Column("jump_id", String, ForeignKey("jumps.id", ondelete="CASCADE"), primary_key=True),
    Column("equipment_id", String, ForeignKey("equipment.id", ondelete="CASCADE"), primary_key=True),
)

class Jump(Base):
    __tablename__ = "jumps"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    date = Column(DateTime(timezone=True), nullable=False)
    location = Column(String, nullable=False)
    latitude = Column(Float, nullable=True)  # GPS latitude
    longitude = Column(Float, nullable=True)  # GPS longitude
    altitude = Column(Integer, nullable=False)  # in feet or meters
    jump_type = Column(Enum(JumpType), nullable=True)  # Tandem, Solo, AFF, etc.
    jump_method = Column(Enum(JumpMethod), nullable=True)  # Plane, Helicopter, BASE, etc.
    checklist_completed = Column(Boolean, default=False)
    notes = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Freefall statistics
    freefall_duration_seconds = Column(Float, nullable=True)
    max_vertical_velocity_ms = Column(Float, nullable=True)
    exit_time = Column(DateTime(timezone=True), nullable=True)
    deployment_time = Column(DateTime(timezone=True), nullable=True)
    
    # Weather data
    weather_temperature_celsius = Column(Float, nullable=True)
    weather_wind_speed_kmh = Column(Float, nullable=True)
    weather_wind_direction_degrees = Column(Integer, nullable=True)
    weather_wind_gusts_kmh = Column(Float, nullable=True)
    weather_code = Column(Integer, nullable=True)
    weather_description = Column(String, nullable=True)
    weather_humidity_percent = Column(Integer, nullable=True)
    weather_pressure_hpa = Column(Float, nullable=True)
    weather_cloud_cover_percent = Column(Integer, nullable=True)
    weather_visibility_km = Column(Float, nullable=True)

    # Relationships
    equipment = relationship("Equipment", secondary=jump_equipment, backref="jumps")
    
    @property
    def equipment_ids(self):
        """Return list of equipment IDs"""
        return [eq.id for eq in self.equipment] if self.equipment else []
