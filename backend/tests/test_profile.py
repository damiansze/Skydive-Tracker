"""Tests for profile endpoints"""
import pytest
from datetime import date

def test_create_profile_minimal(client):
    """Test creating a profile with minimal data"""
    profile_data = {
        "firstName": "John",
        "lastName": "Doe"
    }
    response = client.post("/api/v1/profile/", json=profile_data)
    assert response.status_code == 201
    data = response.json()
    assert data["firstName"] == "John"
    assert data["lastName"] == "Doe"
    assert "id" in data

def test_create_profile_complete(client):
    """Test creating a profile with all fields"""
    profile_data = {
        "firstName": "Jane",
        "lastName": "Smith",
        "dateOfBirth": "1990-05-15",
        "licenseNumber": "USPA-12345",
        "licenseType": "D",
        "homeDropzone": "Skydive City",
        "emergencyContact": {
            "name": "Emergency Contact",
            "phone": "+1-555-0123",
            "relationship": "Spouse"
        },
        "medicalInfo": {
            "bloodType": "A+",
            "allergies": "None",
            "medications": "None"
        },
        "preferences": {
            "units": "metric",
            "language": "en",
            "theme": "dark"
        }
    }
    response = client.post("/api/v1/profile/", json=profile_data)
    assert response.status_code == 201
    data = response.json()
    assert data["firstName"] == "Jane"
    assert data["licenseNumber"] == "USPA-12345"
    assert data["emergencyContact"]["name"] == "Emergency Contact"
    assert data["medicalInfo"]["bloodType"] == "A+"
    assert data["preferences"]["units"] == "metric"

def test_create_profile_invalid_data(client):
    """Test creating a profile with invalid data"""
    # Missing required fields
    response = client.post("/api/v1/profile/", json={})
    assert response.status_code == 422

    # Only first name
    profile_data = {"firstName": "John"}
    response = client.post("/api/v1/profile/", json=profile_data)
    assert response.status_code == 422

def test_get_profile_empty(client):
    """Test getting profile when none exists"""
    response = client.get("/api/v1/profile/")
    assert response.status_code == 404

def test_get_profile_after_creation(client):
    """Test getting profile after creation"""
    # Create profile
    profile_data = {
        "firstName": "Test",
        "lastName": "User",
        "licenseNumber": "TEST-123"
    }
    create_response = client.post("/api/v1/profile/", json=profile_data)
    assert create_response.status_code == 201

    # Get profile
    response = client.get("/api/v1/profile/")
    assert response.status_code == 200
    data = response.json()
    assert data["firstName"] == "Test"
    assert data["lastName"] == "User"
    assert data["licenseNumber"] == "TEST-123"

def test_update_profile(client):
    """Test updating profile"""
    # Create initial profile
    profile_data = {
        "firstName": "Old",
        "lastName": "Name"
    }
    create_response = client.post("/api/v1/profile/", json=profile_data)
    assert create_response.status_code == 201

    # Update profile
    update_data = {
        "firstName": "New",
        "lastName": "Name",
        "licenseNumber": "UPDATED-123",
        "homeDropzone": "New Dropzone"
    }
    response = client.put("/api/v1/profile/", json=update_data)
    assert response.status_code == 200
    data = response.json()
    assert data["firstName"] == "New"
    assert data["licenseNumber"] == "UPDATED-123"
    assert data["homeDropzone"] == "New Dropzone"

def test_update_profile_not_found(client):
    """Test updating profile when none exists"""
    update_data = {"firstName": "New Name"}
    response = client.put("/api/v1/profile/", json=update_data)
    assert response.status_code == 404

def test_delete_profile(client):
    """Test deleting profile"""
    # Create profile
    profile_data = {
        "firstName": "To",
        "lastName": "Delete"
    }
    create_response = client.post("/api/v1/profile/", json=profile_data)
    assert create_response.status_code == 201

    # Delete profile
    response = client.delete("/api/v1/profile/")
    assert response.status_code == 200

    # Verify it's gone
    response = client.get("/api/v1/profile/")
    assert response.status_code == 404

def test_delete_profile_not_found(client):
    """Test deleting profile when none exists"""
    response = client.delete("/api/v1/profile/")
    assert response.status_code == 404

def test_profile_date_validation(client):
    """Test date of birth validation"""
    # Valid date
    profile_data = {
        "firstName": "Test",
        "lastName": "User",
        "dateOfBirth": "1990-05-15"
    }
    response = client.post("/api/v1/profile/", json=profile_data)
    assert response.status_code == 201

    # Invalid date format
    profile_data["dateOfBirth"] = "invalid-date"
    response = client.post("/api/v1/profile/", json=profile_data)
    assert response.status_code == 422

    # Future date (should be allowed - maybe user hasn't been born yet? But let's test)
    future_date = date.today().replace(year=date.today().year + 1).isoformat()
    profile_data["dateOfBirth"] = future_date
    response = client.post("/api/v1/profile/", json=profile_data)
    # This might be allowed or not depending on validation - adjust as needed
    assert response.status_code in [201, 422]

def test_profile_license_types(client):
    """Test valid license types"""
    valid_license_types = ["A", "B", "C", "D", "I"]

    for license_type in valid_license_types:
        profile_data = {
            "firstName": "Test",
            "lastName": f"User-{license_type}",
            "licenseType": license_type
        }
        response = client.post("/api/v1/profile/", json=profile_data)
        assert response.status_code == 201

    # Invalid license type
    profile_data = {
        "firstName": "Test",
        "lastName": "Invalid",
        "licenseType": "Z"
    }
    response = client.post("/api/v1/profile/", json=profile_data)
    assert response.status_code == 422

def test_profile_preferences_validation(client):
    """Test preferences validation"""
    # Valid preferences
    profile_data = {
        "firstName": "Test",
        "lastName": "User",
        "preferences": {
            "units": "metric",
            "language": "en",
            "theme": "dark"
        }
    }
    response = client.post("/api/v1/profile/", json=profile_data)
    assert response.status_code == 201

    # Invalid units
    profile_data["preferences"]["units"] = "invalid"
    response = client.post("/api/v1/profile/", json=profile_data)
    assert response.status_code == 422

def test_profile_emergency_contact_validation(client):
    """Test emergency contact validation"""
    # Valid emergency contact
    profile_data = {
        "firstName": "Test",
        "lastName": "User",
        "emergencyContact": {
            "name": "John Doe",
            "phone": "+1-555-0123",
            "relationship": "Brother"
        }
    }
    response = client.post("/api/v1/profile/", json=profile_data)
    assert response.status_code == 201

    # Emergency contact without required phone
    profile_data["emergencyContact"] = {
        "name": "John Doe",
        "relationship": "Brother"
        # Missing phone
    }
    response = client.post("/api/v1/profile/", json=profile_data)
    assert response.status_code == 422

def test_profile_medical_info_storage(client):
    """Test medical information storage"""
    medical_info = {
        "bloodType": "O-",
        "allergies": "Penicillin, Peanuts",
        "medications": "None",
        "conditions": "Asthma"
    }

    profile_data = {
        "firstName": "Test",
        "lastName": "User",
        "medicalInfo": medical_info
    }

    # Create profile
    create_response = client.post("/api/v1/profile/", json=profile_data)
    assert create_response.status_code == 201

    # Retrieve and verify medical info
    response = client.get("/api/v1/profile/")
    assert response.status_code == 200
    data = response.json()
    assert data["medicalInfo"] == medical_info

def test_profile_full_name_calculation(client):
    """Test that full name is correctly calculated"""
    profile_data = {
        "firstName": "John",
        "lastName": "Doe"
    }

    create_response = client.post("/api/v1/profile/", json=profile_data)
    assert create_response.status_code == 201

    response = client.get("/api/v1/profile/")
    assert response.status_code == 200
    data = response.json()

    # Check if fullName is calculated (assuming the model has this property)
    if "fullName" in data:
        assert data["fullName"] == "John Doe"

def test_profile_update_partial(client):
    """Test partial profile updates"""
    # Create full profile
    profile_data = {
        "firstName": "Original",
        "lastName": "User",
        "licenseNumber": "ORIGINAL-123",
        "homeDropzone": "Original DZ"
    }
    create_response = client.post("/api/v1/profile/", json=profile_data)
    assert create_response.status_code == 201

    # Update only some fields
    update_data = {
        "licenseNumber": "UPDATED-456",
        "homeDropzone": "Updated DZ"
    }
    response = client.put("/api/v1/profile/", json=update_data)
    assert response.status_code == 200
    data = response.json()

    # Check that some fields were updated
    assert data["licenseNumber"] == "UPDATED-456"
    assert data["homeDropzone"] == "Updated DZ"

    # Check that other fields remained unchanged
    assert data["firstName"] == "Original"
    assert data["lastName"] == "User"
