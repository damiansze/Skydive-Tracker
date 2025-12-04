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
    assert data["is_active"] == True  # Default value

def test_create_equipment_complete(client):
    """Test creating equipment with all fields"""
    equipment_data = {
        "name": "Sigma Tandem 220",
        "type": "parachute",
        "manufacturer": "Paratec",
        "model": "Sigma Tandem",
        "serialNumber": "ST220-001",
        "purchaseDate": "2023-06-15",
        "purchasePrice": 3500.00,
        "notes": "Tandem main parachute",
        "is_active": True,
        "specifications": {
            "size": "220 sq ft",
            "color": "White/Blue",
            "packVolume": "Large"
        }
    }
    response = client.post("/api/v1/equipment/", json=equipment_data)
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Sigma Tandem 220"
    assert data["model"] == "Sigma Tandem"
    assert data["serialNumber"] == "ST220-001"
    assert data["purchasePrice"] == 3500.00
    assert data["specifications"]["size"] == "220 sq ft"

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
    # Create test equipment
    equipment_data = [
        {
            "name": "PD Sabre 170",
            "type": "parachute",
            "manufacturer": "Performance Designs"
        },
        {
            "name": "Javelin Odyssey",
            "type": "HARNESSCONTAINER",
            "manufacturer": "Javelin"
        },
        {
            "name": "Optik 3",
            "type": "RESERVE_PARACHUTE",
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
    assert equipment[0]["name"] == "PD Sabre 170"
    assert equipment[1]["type"] == "HARNESSCONTAINER"

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
        "is_active": False
    }
    response = client.put(f"/api/v1/equipment/{equipment_id}", json=update_data)
    assert response.status_code == 200
    updated_equipment = response.json()
    assert updated_equipment["name"] == "Updated Name"
    assert updated_equipment["isActive"] == False
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

    # Delete equipment
    response = client.delete(f"/api/v1/equipment/{equipment_id}")
    assert response.status_code == 200

    # Verify it's gone
    response = client.get(f"/api/v1/equipment/{equipment_id}")
    assert response.status_code == 404

def test_delete_equipment_not_found(client):
    """Test deleting non-existent equipment"""
    response = client.delete("/api/v1/equipment/non-existent-id")
    assert response.status_code == 404

def test_get_equipment_by_type(client):
    """Test filtering equipment by type"""
    # Create equipment of different types
    equipment_data = [
        {"name": "Main 1", "type": "parachute", "manufacturer": "PD"},
        {"name": "Main 2", "type": "parachute", "manufacturer": "PD"},
        {"name": "Reserve", "type": "RESERVE_PARACHUTE", "manufacturer": "Paratec"},
        {"name": "Harness", "type": "HARNESSCONTAINER", "manufacturer": "Javelin"},
    ]

    for eq_data in equipment_data:
        response = client.post("/api/v1/equipment/", json=eq_data)
        assert response.status_code == 201

    # Get only parachutes
    response = client.get("/api/v1/equipment/?type=PARACHUTE")
    assert response.status_code == 200
    equipment = response.json()
    assert len(equipment) == 2
    assert all(eq["type"] == "PARACHUTE" for eq in equipment)

    # Get only reserves
    response = client.get("/api/v1/equipment/?type=RESERVE_PARACHUTE")
    assert response.status_code == 200
    equipment = response.json()
    assert len(equipment) == 1
    assert equipment[0]["type"] == "RESERVE_PARACHUTE"

def test_get_active_equipment(client):
    """Test filtering equipment by active status"""
    # Create equipment with different active statuses
    equipment_data = [
        {"name": "Active 1", "type": "parachute", "manufacturer": "PD", "is_active": True},
        {"name": "Active 2", "type": "parachute", "manufacturer": "PD", "is_active": True},
        {"name": "Inactive", "type": "parachute", "manufacturer": "PD", "is_active": False},
    ]

    for eq_data in equipment_data:
        response = client.post("/api/v1/equipment/", json=eq_data)
        assert response.status_code == 201

    # Get only active equipment
    response = client.get("/api/v1/equipment/?is_active=true")
    assert response.status_code == 200
    equipment = response.json()
    assert len(equipment) == 2
    assert all(eq["isActive"] == True for eq in equipment)

    # Get only inactive equipment
    response = client.get("/api/v1/equipment/?is_active=false")
    assert response.status_code == 200
    equipment = response.json()
    assert len(equipment) == 1
    assert equipment[0]["isActive"] == False

def test_equipment_validation_rules(client):
    """Test equipment validation rules"""
    # Valid equipment types
    valid_types = ["PARACHUTE", "RESERVE_PARACHUTE", "HARNESSCONTAINER", "HELMET", "ALTIMETER", "AAD", "RIG"]

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

def test_equipment_purchase_price_validation(client):
    """Test purchase price validation"""
    # Valid positive price
    equipment_data = {
        "name": "Expensive Equipment",
        "type": "parachute",
        "manufacturer": "Test",
        "purchasePrice": 2500.50
    }
    response = client.post("/api/v1/equipment/", json=equipment_data)
    assert response.status_code == 201

    # Negative price should fail
    equipment_data["purchasePrice"] = -100
    response = client.post("/api/v1/equipment/", json=equipment_data)
    assert response.status_code == 422

def test_equipment_specifications_storage(client):
    """Test that equipment specifications are stored and retrieved correctly"""
    specs = {
        "size": "170 sq ft",
        "color": "Red/White",
        "cells": 7,
        "line_length": "12 ft",
        "pack_volume": "Medium"
    }

    equipment_data = {
        "name": "Spec Test Equipment",
        "type": "parachute",
        "manufacturer": "Test Manufacturer",
        "specifications": specs
    }

    # Create equipment
    create_response = client.post("/api/v1/equipment/", json=equipment_data)
    assert create_response.status_code == 201
    equipment_id = create_response.json()["id"]

    # Retrieve and verify specifications
    response = client.get(f"/api/v1/equipment/{equipment_id}")
    assert response.status_code == 200
    equipment = response.json()
    assert equipment["specifications"] == specs
