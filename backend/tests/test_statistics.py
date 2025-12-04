"""Tests for statistics endpoints"""
from datetime import datetime, timezone

def test_get_total_jumps_empty_db(client):
    """Test getting total jumps count with empty database"""
    response = client.get("/api/v1/statistics/total-jumps")
    assert response.status_code == 200
    data = response.json()
    assert data["total_jumps"] == 0

def test_get_total_jumps_with_data(client):
    """Test getting total jumps count with data"""
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
        },
        {
            "date": datetime(2024, 2, 5, tzinfo=timezone.utc).isoformat(),
            "location": "Interlaken",
            "altitude": 13000,
            "jump_type": "solo"
        }
    ]

    for jump_data in jumps_data:
        response = client.post("/api/v1/jumps/", json=jump_data)
        assert response.status_code == 201

    response = client.get("/api/v1/statistics/total-jumps")
    assert response.status_code == 200
    data = response.json()
    assert data["total_jumps"] == 3

def test_get_statistics_summary_empty_db(client):
    """Test getting statistics summary with empty database"""
    response = client.get("/api/v1/statistics/summary")
    assert response.status_code == 200
    data = response.json()
    assert data["total_jumps"] == 0
    assert data["average_altitude"] == 0
    assert data["unique_locations"] == 0
    assert data["locations"] == []
    assert data["jump_type_counts"] == {}
    assert data["jump_method_counts"] == {}

def test_get_statistics_summary_with_data(client):
    """Test getting statistics summary with comprehensive data"""
    # Create test jumps with various data
    jumps_data = [
        {
            "date": datetime(2024, 1, 15, 10, 0, tzinfo=timezone.utc).isoformat(),
            "location": "Interlaken",
            "altitude": 12000,
            "jump_type": "solo",
        },
        {
            "date": datetime(2024, 1, 20, 14, 30, tzinfo=timezone.utc).isoformat(),
            "location": "Locarno",
            "altitude": 10000,
            "jump_type": "tandem",
        },
        {
            "date": datetime(2024, 2, 5, 11, 15, tzinfo=timezone.utc).isoformat(),
            "location": "Interlaken",
            "altitude": 13000,
            "jump_type": "solo",
        }
    ]

    for jump_data in jumps_data:
        response = client.post("/api/v1/jumps/", json=jump_data)
        assert response.status_code == 201

    response = client.get("/api/v1/statistics/summary")
    assert response.status_code == 200
    data = response.json()

    # Basic counts
    assert data["total_jumps"] == 3

    # Average altitude: (12000 + 10000 + 13000) / 3 = 11666.67
    assert abs(data["average_altitude"] - 11666.67) < 0.01

    # Jump types distribution (stored as lowercase values)
    assert data["jump_type_counts"]["solo"] == 2
    assert data["jump_type_counts"]["tandem"] == 1

    # Unique locations count
    assert data["unique_locations"] == 2
    assert "Interlaken" in data["locations"]
    assert "Locarno" in data["locations"]

def test_get_total_jumps_with_filter(client):
    """Test getting total jumps count with filters"""
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
        },
        {
            "date": datetime(2024, 2, 5, tzinfo=timezone.utc).isoformat(),
            "location": "Interlaken",
            "altitude": 13000,
            "jump_type": "solo"
        }
    ]

    for jump_data in jumps_data:
        response = client.post("/api/v1/jumps/", json=jump_data)
        assert response.status_code == 201

    # Filter by jump type
    response = client.get("/api/v1/statistics/total-jumps?jump_type=solo")
    assert response.status_code == 200
    data = response.json()
    assert data["total_jumps"] == 2

    # Filter by location
    response = client.get("/api/v1/statistics/total-jumps?location=Interlaken")
    assert response.status_code == 200
    data = response.json()
    assert data["total_jumps"] == 2
