"""Tests for weather endpoints"""
import pytest
from datetime import datetime, timezone
from unittest.mock import patch, AsyncMock
import httpx

def test_get_weather_valid_request(client):
    """Test getting weather for valid coordinates and date"""
    weather_request = {
        "latitude": 46.6863,
        "longitude": 7.8632,
        "target_datetime": datetime(2024, 1, 15, 14, 30, tzinfo=timezone.utc).isoformat()
    }

    # Mock the Open-Meteo API response
    mock_response_data = {
        "temperature_2m": [15.5],
        "windspeed_10m": [12.0],
        "winddirection_10m": [180],
        "relativehumidity_2m": [65],
        "surface_pressure": [1013.25],
        "cloudcover": [25],
        "visibility": [15000]
    }

    with patch('httpx.AsyncClient.get') as mock_get:
        mock_response = AsyncMock()
        mock_response.json = AsyncMock(return_value=mock_response_data)
        mock_response.status_code = 200
        mock_response.raise_for_status = AsyncMock()
        mock_get.return_value = mock_response

        response = client.post("/api/v1/weather/", json=weather_request)
        assert response.status_code == 200

        weather_data = response.json()
    weather = weather_data["weather"]
    assert weather["temperature_celsius"] == 15.5
    assert weather["wind_speed_kmh"] == 12.0
    assert weather["wind_direction_degrees"] == 180
    assert weather["humidity_percent"] == 65
    assert weather["pressure_hpa"] == 1013.25
    assert weather["cloud_cover_percent"] == 25
    assert weather["visibility_km"] == 15.0

def test_get_weather_invalid_coordinates(client):
    """Test weather request with invalid coordinates"""
    weather_request = {
        "latitude": 999.0,  # Invalid latitude
        "longitude": 7.8632,
        "target_datetime": datetime.now(timezone.utc).isoformat()
    }

    response = client.post("/api/v1/weather/", json=weather_request)
    assert response.status_code == 422  # Validation error

def test_get_weather_missing_fields(client):
    """Test weather request with missing required fields"""
    # Missing latitude
    weather_request = {
        "longitude": 7.8632,
        "target_datetime": datetime.now(timezone.utc).isoformat()
    }

    response = client.post("/api/v1/weather/", json=weather_request)
    assert response.status_code == 422

    # Missing datetime
    weather_request = {
        "latitude": 46.6863,
        "longitude": 7.8632
    }

    response = client.post("/api/v1/weather/", json=weather_request)
    assert response.status_code == 422

def test_get_weather_api_error(client):
    """Test weather request when external API fails"""
    weather_request = {
        "latitude": 46.6863,
        "longitude": 7.8632,
        "target_datetime": datetime.now(timezone.utc).isoformat()
    }

    with patch('httpx.AsyncClient.get') as mock_get:
        mock_get.side_effect = httpx.RequestError("Network error")

        response = client.post("/api/v1/weather/", json=weather_request)
        assert response.status_code == 500
        assert "error" in response.json()

def test_get_weather_future_date(client):
    """Test weather request for future date (forecast API)"""
    future_date = datetime.now(timezone.utc).replace(hour=14, minute=0, second=0, microsecond=0)
    weather_request = {
        "latitude": 46.6863,
        "longitude": 7.8632,
        "target_datetime": future_date.isoformat()
    }

    mock_response_data = {
        "temperature_2m": [20.0],
        "windspeed_10m": [8.0],
        "winddirection_10m": [90],
        "relativehumidity_2m": [55],
        "surface_pressure": [1015.0],
        "cloudcover": [10],
        "visibility": [20000]
    }

    with patch('httpx.AsyncClient.get') as mock_get:
        mock_response = AsyncMock()
        mock_response.json = AsyncMock(return_value=mock_response_data)
        mock_response.status_code = 200
        mock_response.raise_for_status = AsyncMock()
        mock_get.return_value = mock_response

        response = client.post("/api/v1/weather/", json=weather_request)
        assert response.status_code == 200

        # Verify it uses forecast API URL
        call_args = mock_get.call_args
        assert "forecast" in call_args[0][0]  # URL should contain 'forecast'

def test_get_weather_historical_date(client):
    """Test weather request for historical date (archive API)"""
    # Use a date from 2020 (well in the past)
    historical_date = datetime(2020, 8, 15, 14, 30, tzinfo=timezone.utc)
    weather_request = {
        "latitude": 46.6863,
        "longitude": 7.8632,
        "target_datetime": historical_date.isoformat()
    }

    # Note: Archive API doesn't have visibility, so it should be null
    mock_response_data = {
        "temperature_2m": [18.5],
        "windspeed_10m": [15.0],
        "winddirection_10m": [270],
        "relativehumidity_2m": [70],
        "surface_pressure": [1010.0],
        "cloudcover": [40]
        # No visibility in archive API
    }

    with patch('httpx.AsyncClient.get') as mock_get:
        mock_response = AsyncMock()
        mock_response.json = AsyncMock(return_value=mock_response_data)
        mock_response.status_code = 200
        mock_response.raise_for_status = AsyncMock()
        mock_get.return_value = mock_response

        response = client.post("/api/v1/weather/", json=weather_request)
        assert response.status_code == 200

        weather_data = response.json()
        weather = weather_data["weather"]
        assert weather["temperature_celsius"] == 18.5
        assert weather["visibility_km"] is None  # Should be null for archive data

        # Verify it uses archive API URL
        call_args = mock_get.call_args
        assert "archive" in call_args[0][0]  # URL should contain 'archive'

def test_weather_data_validation(client):
    """Test that weather data validation works correctly"""
    # Test wind direction normalization (360° should become 0°)
    weather_request = {
        "latitude": 46.6863,
        "longitude": 7.8632,
        "target_datetime": datetime.now(timezone.utc).isoformat()
    }

    mock_response_data = {
        "temperature_2m": [15.0],
        "windspeed_10m": [10.0],
        "winddirection_10m": [360],  # Should be normalized to 0
        "relativehumidity_2m": [60],
        "surface_pressure": [1013.0],
        "cloudcover": [20],
        "visibility": [10000]
    }

    with patch('httpx.AsyncClient.get') as mock_get:
        mock_response = AsyncMock()
        mock_response.json = AsyncMock(return_value=mock_response_data)
        mock_response.status_code = 200
        mock_response.raise_for_status = AsyncMock()
        mock_get.return_value = mock_response

        response = client.post("/api/v1/weather/", json=weather_request)
        assert response.status_code == 200

        weather_data = response.json()
        weather = weather_data["weather"]
        assert weather["wind_direction_degrees"] == 0  # Should be normalized

def test_weather_api_timeout(client):
    """Test weather request timeout handling"""
    weather_request = {
        "latitude": 46.6863,
        "longitude": 7.8632,
        "target_datetime": datetime.now(timezone.utc).isoformat()
    }

    with patch('httpx.AsyncClient.get') as mock_get:
        mock_get.side_effect = httpx.TimeoutException("Request timeout")

        response = client.post("/api/v1/weather/", json=weather_request)
        assert response.status_code == 500
        assert "timeout" in response.json()["detail"].lower()

def test_weather_invalid_api_response(client):
    """Test handling of invalid API responses"""
    weather_request = {
        "latitude": 46.6863,
        "longitude": 7.8632,
        "target_datetime": datetime.now(timezone.utc).isoformat()
    }

    with patch('httpx.AsyncClient.get') as mock_get:
        mock_response = AsyncMock()
        mock_response.json.return_value = {"invalid": "response"}
        mock_response.status_code = 200
        mock_response.raise_for_status = AsyncMock()
        mock_get.return_value = mock_response

        response = client.post("/api/v1/weather/", json=weather_request)
        assert response.status_code == 500
        assert "error" in response.json()
