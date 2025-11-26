"""Tests for jump endpoints"""
from datetime import datetime
import pytest

def test_create_jump(client):
    """Test creating a jump"""
    jump_data = {
        "date": datetime.now().isoformat(),
        "location": "Test Dropzone",
        "altitude": 14000,
        "equipment_ids": [],
        "checklist_completed": True,
    }
    response = client.post("/api/v1/jumps/", json=jump_data)
    assert response.status_code == 201
    assert response.json()["location"] == "Test Dropzone"
    assert response.json()["altitude"] == 14000

def test_get_jumps(client):
    """Test getting all jumps"""
    response = client.get("/api/v1/jumps/")
    assert response.status_code == 200
    assert isinstance(response.json(), list)

def test_get_jump_not_found(client):
    """Test getting a non-existent jump"""
    response = client.get("/api/v1/jumps/non-existent-id")
    assert response.status_code == 404
