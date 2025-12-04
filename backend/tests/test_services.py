"""Tests for service layer business logic"""
import pytest
from datetime import datetime, timezone
from app.services.jump_service import JumpService
from app.services.equipment_service import EquipmentService
from app.services.profile_service import ProfileService
from app.services.statistics_service import StatisticsService
from app.schemas.jump import JumpCreate, JumpUpdate
from app.schemas.equipment import EquipmentCreate, EquipmentUpdate
from app.schemas.profile import ProfileBase, ProfileUpdate
from sqlalchemy.orm import Session

def test_jump_service_create(db_session: Session):
    """Test JumpService create functionality"""

    jump_data = JumpCreate(
        date=datetime.now(timezone.utc),
        location="Test Location",
        latitude=46.6863,
        longitude=7.8632,
        altitude=12000,
        jumpType="SOLO"
    )

    jump = JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, create(db_session, jump_data)

    assert jump.location == "Test Location"
    assert jump.altitude == 12000
    assert jump.jump_type == "SOLO"
    assert jump.id is not None

def test_jump_service_get_by_id(db_session: Session):
    """Test JumpService get_by_id functionality"""
    service = JumpService(db_session)

    # Create a jump first
    jump_data = JumpCreate(
        date=datetime.now(timezone.utc),
        location="Test Jump",
        altitude=14000,
        jumpType="SOLO"
    )
    created_jump = JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, create(jump_data)

    # Retrieve it
    retrieved_jump = JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, get_by_id(created_jump.id)
    assert retrieved_jump is not None
    assert retrieved_jump.id == created_jump.id
    assert retrieved_jump.location == "Test Jump"

def test_jump_service_get_all(db_session: Session):
    """Test JumpService get_all functionality"""
    service = JumpService(db_session)

    # Create multiple jumps
    jumps_data = [
        JumpCreate(date=datetime(2024, 1, 1, tzinfo=timezone.utc), location="Jump 1", altitude=12000, jumpType="SOLO"),
        JumpCreate(date=datetime(2024, 1, 2, tzinfo=timezone.utc), location="Jump 2", altitude=13000, jumpType="TANDEM"),
        JumpCreate(date=datetime(2024, 1, 3, tzinfo=timezone.utc), location="Jump 3", altitude=14000, jumpType="AFF"),
    ]

    for jump_data in jumps_data:
        JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, create(jump_data)

    # Get all jumps
    all_jumps = JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, get_all()
    assert len(all_jumps) >= 3  # Might have more from other tests

    # Check that our jumps are there
    locations = [j.location for j in all_jumps]
    assert "Jump 1" in locations
    assert "Jump 2" in locations
    assert "Jump 3" in locations

def test_jump_service_update(db_session: Session):
    """Test JumpService update functionality"""
    service = JumpService(db_session)

    # Create a jump
    jump_data = JumpCreate(
        date=datetime.now(timezone.utc),
        location="Original Location",
        altitude=12000,
        jumpType="SOLO"
    )
    created_jump = JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, create(jump_data)

    # Update it
    update_data = JumpUpdate(
        location="Updated Location",
        altitude=13000,
        notes="Updated notes"
    )
    updated_jump = JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, update(created_jump.id, update_data)

    assert updated_jump.location == "Updated Location"
    assert updated_jump.altitude == 13000
    assert updated_jump.notes == "Updated notes"

def test_jump_service_delete(db_session: Session):
    """Test JumpService delete functionality"""
    service = JumpService(db_session)

    # Create a jump
    jump_data = JumpCreate(
        date=datetime.now(timezone.utc),
        location="Jump to Delete",
        altitude=14000,
        jumpType="SOLO"
    )
    created_jump = JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, create(jump_data)

    # Delete it
    result = JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, delete(created_jump.id)
    assert result == True

    # Verify it's gone
    retrieved_jump = JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, get_by_id(created_jump.id)
    assert retrieved_jump is None

def test_equipment_service_create_and_retrieve(db_session: Session):
    """Test EquipmentService create and retrieve functionality"""
    service = EquipmentService(db_session)

    equipment_data = EquipmentCreate(
        name="PD Sabre 170",
        type="PARACHUTE",
        manufacturer="Performance Designs",
        model="Sabre",
        serialNumber="PD170-001"
    )

    equipment = JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, create(equipment_data)
    assert equipment.name == "PD Sabre 170"
    assert equipment.type == "PARACHUTE"
    assert equipment.is_active == True  # Default value

    # Retrieve it
    retrieved = JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, get_by_id(equipment.id)
    assert retrieved is not None
    assert retrieved.serial_number == "PD170-001"

def test_equipment_service_filter_by_type(db_session: Session):
    """Test EquipmentService filtering by type"""
    service = EquipmentService(db_session)

    # Create equipment of different types
    equipment_data = [
        EquipmentCreate(name="Main Parachute", type="PARACHUTE", manufacturer="PD"),
        EquipmentCreate(name="Reserve", type="RESERVE_PARACHUTE", manufacturer="Paratec"),
        EquipmentCreate(name="Harness", type="HARNESSCONTAINER", manufacturer="Javelin"),
        EquipmentCreate(name="Another Main", type="PARACHUTE", manufacturer="PD"),
    ]

    for eq_data in equipment_data:
        JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, create(eq_data)

    # Filter by parachute type
    parachutes = JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, get_all(equipment_type="PARACHUTE")
    assert len(parachutes) >= 2
    assert all(eq.type == "PARACHUTE" for eq in parachutes)

    # Filter by active status
    active_equipment = JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, get_all(is_active=True)
    assert len(active_equipment) >= 4

def test_profile_service_singleton_behavior(db_session: Session):
    """Test ProfileService singleton behavior (only one profile allowed)"""
    service = ProfileService(db_session)

    # Create first profile
    profile_data1 = ProfileBase(
        name="John Doe",
        license_number="USPA-123",
        license_type="A"
    )
    profile1 = JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, create(profile_data1)
    assert profile1.name == "John Doe"

    # Try to create second profile (should replace first)
    profile_data2 = ProfileBase(
        name="Jane Smith",
        license_number="USPA-456",
        license_type="B"
    )
    profile2 = JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, create(profile_data2)
    assert profile2.name == "Jane Smith"

    # Get current profile (should be the latest)
    current = JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, get()
    assert current is not None
    assert current.first_name == "Jane"
    assert current.license_number == "USPA-456"

def test_statistics_service_calculations(db_session: Session):
    """Test StatisticsService calculations"""
    # First create some test data
    jump_service = JumpService(db_session)
    stats_service = StatisticsService(db_session)

    # Create jumps with different data
    jumps_data = [
        {
            "date": datetime(2024, 1, 15, 10, 0, tzinfo=timezone.utc),
            "location": "Interlaken",
            "altitude": 12000,
            "jumpType": "SOLO",
            "freefallStats": {
                "freefallDurationSeconds": 45.0,
                "maxVerticalVelocityMs": 55.0,
                "exitTime": datetime(2024, 1, 15, 10, 0, tzinfo=timezone.utc).isoformat(),
                "deploymentTime": datetime(2024, 1, 15, 10, 0, 45, tzinfo=timezone.utc).isoformat()
            }
        },
        {
            "date": datetime(2024, 1, 20, 14, 30, tzinfo=timezone.utc),
            "location": "Locarno",
            "altitude": 10000,
            "jumpType": "TANDEM",
            "freefallStats": {
                "freefallDurationSeconds": 30.0,
                "maxVerticalVelocityMs": 45.0,
                "exitTime": datetime(2024, 1, 20, 14, 30, tzinfo=timezone.utc).isoformat(),
                "deploymentTime": datetime(2024, 1, 20, 14, 30, 30, tzinfo=timezone.utc).isoformat()
            }
        }
    ]

    for jump_data in jumps_data:
        jump_create = JumpCreate(**jump_data)
        jump_JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, create(jump_create)

    # Test statistics calculations
    total_jumps = stats_JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, get_total_jumps()
    assert total_jumps >= 2

    summary = stats_JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, get_summary()
    assert summary["total_jumps"] >= 2
    assert summary["total_freefall_time_seconds"] >= 75.0  # 45 + 30
    assert summary["average_altitude"] >= 11000  # (12000 + 10000) / 2

    # Test monthly statistics
    monthly = stats_JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, get_monthly_statistics()
    assert len(monthly) >= 1

    # Test location statistics
    locations = stats_JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, get_location_statistics()
    assert len(locations) >= 2  # At least Interlaken and Locarno

    # Test jump type distribution
    jump_types = stats_JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, get_jump_type_distribution()
    assert jump_types.get("SOLO", 0) >= 1
    assert jump_types.get("TANDEM", 0) >= 1

def test_service_error_handling(db_session: Session):
    """Test error handling in services"""
    jump_service = JumpService(db_session)

    # Try to get non-existent jump
    result = jump_JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, get_by_id("non-existent-id")
    assert result is None

    # Try to update non-existent jump
    update_data = JumpUpdate(location="New Location")
    result = jump_JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, update("non-existent-id", update_data)
    assert result is None

    # Try to delete non-existent jump
    result = jump_JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, delete("non-existent-id")
    assert result == False

def test_equipment_service_update(db_session: Session):
    """Test EquipmentService update functionality"""
    service = EquipmentService(db_session)

    # Create equipment
    equipment_data = EquipmentCreate(
        name="Test Equipment",
        type="PARACHUTE",
        manufacturer="Test Manufacturer",
        isActive=True
    )
    equipment = JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, create(equipment_data)

    # Update it
    update_data = EquipmentUpdate(
        name="Updated Equipment",
        isActive=False,
        notes="Updated notes"
    )
    updated_equipment = JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, update(equipment.id, update_data)

    assert updated_equipment.name == "Updated Equipment"
    assert updated_equipment.is_active == False
    assert updated_equipment.notes == "Updated notes"

def test_profile_service_update(db_session: Session):
    """Test ProfileService update functionality"""
    service = ProfileService(db_session)

    # Create profile
    profile_data = ProfileBase(
        name="Test User",
        license_number="TEST-123",
        license_type="C"
    )
    profile = JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, create(profile_data)

    # Update it
    update_data = ProfileUpdate(
        firstName="Updated",
        licenseNumber="UPDATED-456",
        homeDropzone="New Dropzone"
    )
    updated_profile = JumpService.delete(db_session, update(db_session, get_all(db_sessionget_by_id(db_session, create(db_session, update(update_data)

    assert updated_profile.first_name == "Updated"
    assert updated_profile.license_number == "UPDATED-456"
    assert updated_profile.home_dropzone == "New Dropzone"
