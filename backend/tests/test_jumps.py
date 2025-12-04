"""Tests for jump endpoints"""
from datetime import datetime, timezone
import pytest
import uuid

def test_create_jump_minimal(client):
    """Test creating a jump with minimal data"""
    jump_data = {
        "date": datetime(2024, 1, 15, 14, 30, tzinfo=timezone.utc).isoformat(),
        "location": "Test Dropzone",
        "altitude": 14000,
        "jump_type": "solo"
    }
    response = client.post("/api/v1/jumps/", json=jump_data)
    assert response.status_code == 201
    data = response.json()
    assert data["location"] == "Test Dropzone"
    assert data["altitude"] == 14000
    assert data["jump_type"] == "SOLO"
    assert "id" in data
    assert "created_at" in data

def test_create_jump_complete(client):
    """Test creating a jump with all optional fields"""
    jump_data = {
        "date": datetime.now(timezone.utc).isoformat(),
        "location": "Interlaken",
        "latitude": 46.6863,
        "longitude": 7.8632,
        "altitude": 12000,
        "jump_type": "tandem",
        "notes": "Great jump with student",
        "equipmentIds": [],
        "freefallStats": {
            "freefallDurationSeconds": 45.5,
            "maxVerticalVelocityMs": 55.0,
            "exitTime": datetime.now(timezone.utc).isoformat(),
            "deploymentTime": datetime.now(timezone.utc).isoformat()
        },
        "weather": {
            "temperatureCelsius": 15.5,
            "windSpeedKmh": 12.0,
            "windDirectionDegrees": 180,
            "humidityPercent": 65,
            "pressureHpa": 1013.25,
            "cloudCoverPercent": 25,
            "visibilityKm": 15.0
        }
    }
    response = client.post("/api/v1/jumps/", json=jump_data)
    assert response.status_code == 201
    data = response.json()
    assert data["location"] == "Interlaken"
    assert data["latitude"] == 46.6863
    assert data["longitude"] == 7.8632
    assert data["jumpType"] == "TANDEM"
    assert data["notes"] == "Great jump with student"
    assert data["freefallStats"]["freefallDurationSeconds"] == 45.5
    assert data["weather"]["temperatureCelsius"] == 15.5

def test_create_jump_invalid_data(client):
    """Test creating a jump with invalid data"""
    # Missing required fields
    response = client.post("/api/v1/jumps/", json={})
    assert response.status_code == 422  # Validation error

    # Invalid jump type
    jump_data = {
        "date": datetime.now(timezone.utc).isoformat(),
        "location": "Test",
        "altitude": 14000,
        "jump_type": "INVALID_TYPE"
    }
    response = client.post("/api/v1/jumps/", json=jump_data)
    assert response.status_code == 422

    # Invalid altitude
    jump_data = {
        "date": datetime.now(timezone.utc).isoformat(),
        "location": "Test",
        "altitude": -100,  # Invalid negative altitude
        "jump_type": "solo"
    }
    response = client.post("/api/v1/jumps/", json=jump_data)
    assert response.status_code == 422

def test_get_jumps_empty(client):
    """Test getting all jumps when database is empty"""
    response = client.get("/api/v1/jumps/")
    assert response.status_code == 200
    assert response.json() == []

def test_get_jumps_with_data(client):
    """Test getting all jumps when data exists"""
    # Create some test jumps
    jumps_data = [
        {
            "date": datetime(2024, 1, 15, tzinfo=timezone.utc).isoformat(),
            "location": "Interlaken",
            "altitude": 12000,
            "jump_type": "solo"
        },
        {
            "date": datetime(2024, 1, 20, tzinfo=timezone.utc).isoformat(),
            "location": "Locarno",
            "altitude": 10000,
            "jump_type": "tandem"
        }
    ]

    for jump_data in jumps_data:
        response = client.post("/api/v1/jumps/", json=jump_data)
        assert response.status_code == 201

    # Get all jumps
    response = client.get("/api/v1/jumps/")
    assert response.status_code == 200
    jumps = response.json()
    assert len(jumps) == 2
    assert jumps[0]["location"] == "Interlaken"
    assert jumps[1]["location"] == "Locarno"

def test_get_jump_by_id(client):
    """Test getting a specific jump by ID"""
    # Create a jump
    jump_data = {
        "date": datetime.now(timezone.utc).isoformat(),
        "location": "Test Jump",
        "altitude": 14000,
        "jump_type": "solo"
    }
    create_response = client.post("/api/v1/jumps/", json=jump_data)
    assert create_response.status_code == 201
    jump_id = create_response.json()["id"]

    # Get the jump by ID
    response = client.get(f"/api/v1/jumps/{jump_id}")
    assert response.status_code == 200
    jump = response.json()
    assert jump["id"] == jump_id
    assert jump["location"] == "Test Jump"

def test_get_jump_not_found(client):
    """Test getting a non-existent jump"""
    response = client.get("/api/v1/jumps/non-existent-id")
    assert response.status_code == 404
    assert "detail" in response.json()

def test_update_jump(client):
    """Test updating a jump"""
    # Create a jump
    jump_data = {
        "date": datetime.now(timezone.utc).isoformat(),
        "location": "Original Location",
        "altitude": 14000,
        "jump_type": "solo"
    }
    create_response = client.post("/api/v1/jumps/", json=jump_data)
    jump_id = create_response.json()["id"]

    # Update the jump
    update_data = {
        "location": "Updated Location",
        "altitude": 13000,
        "notes": "Updated notes"
    }
    response = client.put(f"/api/v1/jumps/{jump_id}", json=update_data)
    assert response.status_code == 200
    updated_jump = response.json()
    assert updated_jump["location"] == "Updated Location"
    assert updated_jump["altitude"] == 13000
    assert updated_jump["notes"] == "Updated notes"

def test_update_jump_not_found(client):
    """Test updating a non-existent jump"""
    update_data = {"location": "New Location"}
    response = client.put("/api/v1/jumps/non-existent-id", json=update_data)
    assert response.status_code == 404

def test_delete_jump(client):
    """Test deleting a jump"""
    # Create a jump
    jump_data = {
        "date": datetime.now(timezone.utc).isoformat(),
        "location": "Jump to Delete",
        "altitude": 14000,
        "jump_type": "solo"
    }
    create_response = client.post("/api/v1/jumps/", json=jump_data)
    jump_id = create_response.json()["id"]

    # Delete the jump
    response = client.delete(f"/api/v1/jumps/{jump_id}")
    assert response.status_code == 200

    # Verify it's gone
    response = client.get(f"/api/v1/jumps/{jump_id}")
    assert response.status_code == 404

def test_delete_jump_not_found(client):
    """Test deleting a non-existent jump"""
    response = client.delete("/api/v1/jumps/non-existent-id")
    assert response.status_code == 404
