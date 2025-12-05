"""Weather API endpoints"""
from fastapi import APIRouter, HTTPException
from app.schemas.weather import WeatherRequest, WeatherResponse
from app.services.weather_service import WeatherService
from app.core.logging_config import get_logger

logger = get_logger(__name__)
router = APIRouter()


@router.post("/", response_model=WeatherResponse)
async def get_weather(request: WeatherRequest):
    """
    Get weather data for a specific location and time.
    
    This endpoint fetches weather data from Open-Meteo API for:
    - Historical data (up to several years back)
    - Current weather
    - Forecast (up to 16 days ahead)
    
    The weather data includes:
    - Temperature (°C)
    - Wind speed and direction (km/h, degrees)
    - Wind gusts (km/h)
    - Weather condition (code and description)
    - Humidity (%)
    - Pressure (hPa)
    - Cloud cover (%)
    - Visibility (km)
    """
    logger.info(
        "Weather request received",
        extra={
            "event": "weather_request",
            "latitude": request.latitude,
            "longitude": request.longitude,
            "datetime": request.target_datetime.isoformat(),
        }
    )
    
    response = await WeatherService.get_weather_for_location(
        latitude=request.latitude,
        longitude=request.longitude,
        target_datetime=request.target_datetime,
    )

    if not response.success:
        raise HTTPException(status_code=500, detail=response.error or "Weather data fetch failed")

    return response

