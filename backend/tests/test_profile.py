"""Tests for profile endpoints"""
import pytest

def test_create_profile_minimal(client):
    """Test creating a profile with minimal data"""
    profile_data = {
        "name": "John Doe"
    }
    response = client.post("/api/v1/profile/", json=profile_data)
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "John Doe"
    assert "id" in data

def test_create_profile_complete(client):
    """Test creating a profile with all fields"""
    profile_data = {
        "name": "Jane Smith",
        "license_number": "USPA-12345",
        "license_type": "A"
    }
    response = client.post("/api/v1/profile/", json=profile_data)
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Jane Smith"
    assert data["license_number"] == "USPA-12345"
    assert data["license_type"] == "A"
    assert "id" in data

def test_get_profile_empty(client):
    """Test getting profile when none exists"""
    response = client.get("/api/v1/profile/")
    assert response.status_code == 404

def test_get_profile_after_creation(client):
    """Test getting profile after creation"""
    # Create profile first
    profile_data = {"name": "Test User"}
    create_response = client.post("/api/v1/profile/", json=profile_data)
    assert create_response.status_code == 201

    # Now get it
    response = client.get("/api/v1/profile/")
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Test User"

def test_update_profile(client):
    """Test updating a profile"""
    # Create profile first
    profile_data = {"name": "Original Name"}
    create_response = client.post("/api/v1/profile/", json=profile_data)
    assert create_response.status_code == 201

    # Update it
    update_data = {"name": "Updated Name", "license_number": "NEW-123"}
    response = client.put("/api/v1/profile/", json=update_data)
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Updated Name"
    assert data["license_number"] == "NEW-123"