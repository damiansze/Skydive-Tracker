"""Weather schemas for API validation"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime as dt


class WeatherData(BaseModel):
    """Weather data model for a jump location and time"""
    temperature_celsius: Optional[float] = Field(default=None, description="Temperature in Celsius")
    wind_speed_kmh: Optional[float] = Field(default=None, description="Wind speed in km/h")
    wind_direction_degrees: Optional[int] = Field(default=None, ge=0, le=360, description="Wind direction in degrees (0-360, where 360=North)")
    wind_gusts_kmh: Optional[float] = Field(default=None, description="Wind gusts in km/h")
    weather_code: Optional[int] = Field(default=None, description="WMO weather code")
    weather_description: Optional[str] = Field(default=None, description="Human readable weather description")
    humidity_percent: Optional[int] = Field(default=None, ge=0, le=100, description="Relative humidity in percent")
    pressure_hpa: Optional[float] = Field(default=None, description="Surface pressure in hPa")
    cloud_cover_percent: Optional[int] = Field(default=None, ge=0, le=100, description="Cloud cover in percent")
    visibility_km: Optional[float] = Field(default=None, description="Visibility in kilometers")

    @staticmethod
    def get_wind_direction_name(degrees: Optional[int]) -> Optional[str]:
        """Convert wind direction degrees to compass direction"""
        if degrees is None:
            return None
        directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                      "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        index = round(degrees / 22.5) % 16
        return directions[index]
    
    @staticmethod
    def get_weather_description_from_code(code: Optional[int]) -> Optional[str]:
        """Convert WMO weather code to human readable description"""
        if code is None:
            return None
        
        weather_codes = {
            0: "Klar",
            1: "Überwiegend klar",
            2: "Teilweise bewölkt",
            3: "Bewölkt",
            45: "Nebel",
            48: "Gefrierender Nebel",
            51: "Leichter Nieselregen",
            53: "Mäßiger Nieselregen",
            55: "Starker Nieselregen",
            56: "Leichter gefrierender Nieselregen",
            57: "Starker gefrierender Nieselregen",
            61: "Leichter Regen",
            63: "Mäßiger Regen",
            65: "Starker Regen",
            66: "Leichter gefrierender Regen",
            67: "Starker gefrierender Regen",
            71: "Leichter Schneefall",
            73: "Mäßiger Schneefall",
            75: "Starker Schneefall",
            77: "Schneekörner",
            80: "Leichte Regenschauer",
            81: "Mäßige Regenschauer",
            82: "Heftige Regenschauer",
            85: "Leichte Schneeschauer",
            86: "Starke Schneeschauer",
            95: "Gewitter",
            96: "Gewitter mit leichtem Hagel",
            99: "Gewitter mit starkem Hagel",
        }
        return weather_codes.get(code, f"Unbekannt ({code})")


class WeatherRequest(BaseModel):
    """Request model for fetching weather data"""
    latitude: float = Field(..., ge=-90, le=90, description="Latitude")
    longitude: float = Field(..., ge=-180, le=180, description="Longitude")
    target_datetime: dt = Field(..., alias="datetime", description="Date and time for weather data")
    
    model_config = {
        "populate_by_name": True,
    }


class WeatherResponse(BaseModel):
    """Response model for weather data"""
    weather: Optional[WeatherData] = None
    success: bool = True
    error: Optional[str] = None
