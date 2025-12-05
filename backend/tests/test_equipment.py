"""Tests for equipment endpoints"""
from datetime import datetime, timezone
import pytest

def test_create_equipment_minimal(client):
    """Test creating equipment with minimal data"""
    equipment_data = {
        "name": "PD Sabre 170",
        "type": "parachute",
        "manufacturer": "Performance Designs"
    }
    response = client.post("/api/v1/equipment/", json=equipment_data)
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "PD Sabre 170"
    assert data["type"] == "parachute"
    assert data["manufacturer"] == "Performance Designs"
    assert "id" in data
    assert data["is_active"] == 1  # Default value

def test_create_equipment_complete(client):
    """Test creating equipment with all fields"""
    equipment_data = {
        "name": "Sigma Tandem 220",
        "type": "parachute",
        "manufacturer": "Paratec",
        "model": "Sigma Tandem",
        "serial_number": "ST220-001",
        "notes": "Tandem main parachute",
        "is_active": 1
    }
    response = client.post("/api/v1/equipment/", json=equipment_data)
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Sigma Tandem 220"
    assert data["model"] == "Sigma Tandem"
    assert data["serial_number"] == "ST220-001"
    assert data["is_active"] == 1

def test_create_equipment_invalid_data(client):
    """Test creating equipment with invalid data"""
    # Missing required fields
    response = client.post("/api/v1/equipment/", json={})
    assert response.status_code == 422

    # Invalid equipment type
    equipment_data = {
        "name": "Test Equipment",
        "type": "INVALID_TYPE",
        "manufacturer": "Test Manufacturer"
    }
    response = client.post("/api/v1/equipment/", json=equipment_data)
    assert response.status_code == 422

def test_get_equipment_empty(client):
    """Test getting all equipment when database is empty"""
    response = client.get("/api/v1/equipment/")
    assert response.status_code == 200
    assert response.json() == []

def test_get_equipment_with_data(client):
    """Test getting all equipment when data exists"""
    # Create test equipment using valid types from EquipmentType enum
    equipment_data = [
        {
            "name": "PD Sabre 170",
            "type": "parachute",
            "manufacturer": "Performance Designs"
        },
        {
            "name": "Javelin Odyssey",
            "type": "harness",
            "manufacturer": "Javelin"
        },
        {
            "name": "Optik 3",
            "type": "reserve",
            "manufacturer": "Paratec"
        }
    ]

    for eq_data in equipment_data:
        response = client.post("/api/v1/equipment/", json=eq_data)
        assert response.status_code == 201

    # Get all equipment
    response = client.get("/api/v1/equipment/")
    assert response.status_code == 200
    equipment = response.json()
    assert len(equipment) == 3

def test_get_equipment_by_id(client):
    """Test getting specific equipment by ID"""
    # Create equipment
    equipment_data = {
        "name": "Test Parachute",
        "type": "parachute",
        "manufacturer": "Test Manufacturer"
    }
    create_response = client.post("/api/v1/equipment/", json=equipment_data)
    equipment_id = create_response.json()["id"]

    # Get equipment by ID
    response = client.get(f"/api/v1/equipment/{equipment_id}")
    assert response.status_code == 200
    equipment = response.json()
    assert equipment["id"] == equipment_id
    assert equipment["name"] == "Test Parachute"

def test_get_equipment_not_found(client):
    """Test getting non-existent equipment"""
    response = client.get("/api/v1/equipment/non-existent-id")
    assert response.status_code == 404

def test_update_equipment(client):
    """Test updating equipment"""
    # Create equipment
    equipment_data = {
        "name": "Old Name",
        "type": "parachute",
        "manufacturer": "Old Manufacturer"
    }
    create_response = client.post("/api/v1/equipment/", json=equipment_data)
    equipment_id = create_response.json()["id"]

    # Update equipment
    update_data = {
        "name": "Updated Name",
        "manufacturer": "Updated Manufacturer",
        "notes": "Updated notes",
        "is_active": 0
    }
    response = client.put(f"/api/v1/equipment/{equipment_id}", json=update_data)
    assert response.status_code == 200
    updated_equipment = response.json()
    assert updated_equipment["name"] == "Updated Name"
    assert updated_equipment["is_active"] == 0
    assert updated_equipment["notes"] == "Updated notes"

def test_update_equipment_not_found(client):
    """Test updating non-existent equipment"""
    update_data = {"name": "New Name"}
    response = client.put("/api/v1/equipment/non-existent-id", json=update_data)
    assert response.status_code == 404

def test_delete_equipment(client):
    """Test deleting equipment"""
    # Create equipment
    equipment_data = {
        "name": "Equipment to Delete",
        "type": "parachute",
        "manufacturer": "Test Manufacturer"
    }
    create_response = client.post("/api/v1/equipment/", json=equipment_data)
    equipment_id = create_response.json()["id"]

    # Delete equipment - returns 204 No Content
    response = client.delete(f"/api/v1/equipment/{equipment_id}")
    assert response.status_code == 204

    # Verify it's gone
    response = client.get(f"/api/v1/equipment/{equipment_id}")
    assert response.status_code == 404

def test_delete_equipment_not_found(client):
    """Test deleting non-existent equipment"""
    response = client.delete("/api/v1/equipment/non-existent-id")
    assert response.status_code == 404

def test_equipment_validation_rules(client):
    """Test equipment validation rules"""
    # Valid equipment types from EquipmentType enum
    valid_types = ["parachute", "harness", "reserve", "altimeter", "helmet", "goggles", "other"]

    for eq_type in valid_types:
        equipment_data = {
            "name": f"Test {eq_type}",
            "type": eq_type,
            "manufacturer": "Test Manufacturer"
        }
        response = client.post("/api/v1/equipment/", json=equipment_data)
        assert response.status_code == 201

    # Invalid equipment type
    equipment_data = {
        "name": "Invalid Type",
        "type": "INVALID_TYPE",
        "manufacturer": "Test Manufacturer"
    }
    response = client.post("/api/v1/equipment/", json=equipment_data)
    assert response.status_code == 422

def test_equipment_with_notes(client):
    """Test creating equipment with notes"""
    equipment_data = {
        "name": "Equipment with Notes",
        "type": "parachute",
        "manufacturer": "Test",
        "notes": "This is a test note"
    }
    response = client.post("/api/v1/equipment/", json=equipment_data)
    assert response.status_code == 201
    data = response.json()
    assert data["notes"] == "This is a test note"

def test_equipment_active_status(client):
    """Test equipment active/inactive status"""
    # Create active equipment
    equipment_data = {
        "name": "Active Equipment",
        "type": "parachute",
        "manufacturer": "Test",
        "is_active": 1
    }
    response = client.post("/api/v1/equipment/", json=equipment_data)
    assert response.status_code == 201
    assert response.json()["is_active"] == 1

    # Create inactive equipment
    equipment_data = {
        "name": "Inactive Equipment",
        "type": "parachute",
        "manufacturer": "Test",
        "is_active": 0
    }
    response = client.post("/api/v1/equipment/", json=equipment_data)
    assert response.status_code == 201
    assert response.json()["is_active"] == 0
