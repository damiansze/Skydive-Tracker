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
            "jumpType": "SOLO"
        },
        {
            "date": datetime(2024, 1, 20, tzinfo=timezone.utc).isoformat(),
            "location": "Locarno",
            "altitude": 10000,
            "jumpType": "TANDEM"
        },
        {
            "date": datetime(2024, 2, 5, tzinfo=timezone.utc).isoformat(),
            "location": "Interlaken",
            "altitude": 13000,
            "jumpType": "SOLO"
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
    assert data["total_freefall_time_seconds"] == 0
    assert data["average_altitude"] == 0
    assert data["jump_types"] == {}
    assert data["locations"] == {}
    assert data["monthly_jumps"] == []

def test_get_statistics_summary_with_data(client):
    """Test getting statistics summary with comprehensive data"""
    # Create test jumps with various data
    jumps_data = [
        {
            "date": datetime(2024, 1, 15, 10, 0, tzinfo=timezone.utc).isoformat(),
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
            "date": datetime(2024, 1, 20, 14, 30, tzinfo=timezone.utc).isoformat(),
            "location": "Locarno",
            "altitude": 10000,
            "jumpType": "TANDEM",
            "freefallStats": {
                "freefallDurationSeconds": 30.0,
                "maxVerticalVelocityMs": 45.0,
                "exitTime": datetime(2024, 1, 20, 14, 30, tzinfo=timezone.utc).isoformat(),
                "deploymentTime": datetime(2024, 1, 20, 14, 30, 30, tzinfo=timezone.utc).isoformat()
            }
        },
        {
            "date": datetime(2024, 2, 5, 11, 15, tzinfo=timezone.utc).isoformat(),
            "location": "Interlaken",
            "altitude": 13000,
            "jumpType": "SOLO",
            "freefallStats": {
                "freefallDurationSeconds": 60.0,
                "maxVerticalVelocityMs": 58.0,
                "exitTime": datetime(2024, 2, 5, 11, 15, tzinfo=timezone.utc).isoformat(),
                "deploymentTime": datetime(2024, 2, 5, 11, 16, tzinfo=timezone.utc).isoformat()
            }
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
    assert data["total_freefall_time_seconds"] == 135.0  # 45 + 30 + 60

    # Average altitude: (12000 + 10000 + 13000) / 3 = 11666.67
    assert abs(data["average_altitude"] - 11666.67) < 0.01

    # Jump types distribution
    assert data["jump_types"]["SOLO"] == 2
    assert data["jump_types"]["TANDEM"] == 1

    # Locations distribution
    assert data["locations"]["Interlaken"] == 2
    assert data["locations"]["Locarno"] == 1

    # Monthly jumps
    assert len(data["monthly_jumps"]) == 2  # January and February
    january_data = next(m for m in data["monthly_jumps"] if m["month"] == "2024-01")
    february_data = next(m for m in data["monthly_jumps"] if m["month"] == "2024-02")
    assert january_data["count"] == 2
    assert february_data["count"] == 1

    # Performance stats
    assert data["max_freefall_time_seconds"] == 60.0
    assert data["average_freefall_time_seconds"] == 45.0  # 135 / 3
    assert abs(data["max_velocity_kmh"] - (58.0 * 3.6)) < 0.1  # Convert m/s to km/h

def test_get_monthly_statistics(client):
    """Test getting monthly jump statistics"""
    # Create jumps in different months
    months_data = [
        ("2024-01", 2),  # 2 jumps in January
        ("2024-02", 1),  # 1 jump in February
        ("2024-03", 3),  # 3 jumps in March
    ]

    jump_count = 0
    for month_year, count in months_data:
        year, month = map(int, month_year.split('-'))
        for i in range(count):
            jump_data = {
                "date": datetime(year, month, i+1, tzinfo=timezone.utc).isoformat(),
                "location": f"Location {jump_count}",
                "altitude": 12000,
                "jumpType": "SOLO"
            }
            response = client.post("/api/v1/jumps/", json=jump_data)
            assert response.status_code == 201
            jump_count += 1

    response = client.get("/api/v1/statistics/monthly")
    assert response.status_code == 200
    data = response.json()

    # Should have 3 months
    assert len(data) == 3

    # Check each month's data
    for item in data:
        if item["month"] == "2024-01":
            assert item["count"] == 2
        elif item["month"] == "2024-02":
            assert item["count"] == 1
        elif item["month"] == "2024-03":
            assert item["count"] == 3

def test_get_jump_types_distribution(client):
    """Test getting jump types distribution"""
    jump_types_data = [
        ("SOLO", 3),
        ("TANDEM", 2),
        ("AFF", 1),
        ("COACH", 1),
    ]

    for jump_type, count in jump_types_data:
        for i in range(count):
            jump_data = {
                "date": datetime.now(timezone.utc).isoformat(),
                "location": f"Location {jump_type} {i}",
                "altitude": 12000,
                "jumpType": jump_type
            }
            response = client.post("/api/v1/jumps/", json=jump_data)
            assert response.status_code == 201

    response = client.get("/api/v1/statistics/jump-types")
    assert response.status_code == 200
    data = response.json()

    assert data["SOLO"] == 3
    assert data["TANDEM"] == 2
    assert data["AFF"] == 1
    assert data["COACH"] == 1

def test_get_location_statistics(client):
    """Test getting location-based statistics"""
    locations_data = [
        ("Interlaken", 3, 12500),  # 3 jumps, avg altitude 12500
        ("Locarno", 2, 11000),     # 2 jumps, avg altitude 11000
        ("Zürich", 1, 10000),      # 1 jump, avg altitude 10000
    ]

    for location, count, altitude in locations_data:
        for i in range(count):
            jump_data = {
                "date": datetime.now(timezone.utc).isoformat(),
                "location": location,
                "altitude": altitude,
                "jumpType": "SOLO"
            }
            response = client.post("/api/v1/jumps/", json=jump_data)
            assert response.status_code == 201

    response = client.get("/api/v1/statistics/locations")
    assert response.status_code == 200
    data = response.json()

    assert len(data) == 3

    # Check each location's stats
    interlaken_stats = next(loc for loc in data if loc["location"] == "Interlaken")
    locarno_stats = next(loc for loc in data if loc["location"] == "Locarno")
    zurich_stats = next(loc for loc in data if loc["location"] == "Zürich")

    assert interlaken_stats["jump_count"] == 3
    assert interlaken_stats["average_altitude"] == 12500
    assert locarno_stats["jump_count"] == 2
    assert locarno_stats["average_altitude"] == 11000
    assert zurich_stats["jump_count"] == 1
    assert zurich_stats["average_altitude"] == 10000
