"""Weather service for fetching weather data from Open-Meteo API"""
import httpx
from datetime import datetime, timedelta
from typing import Optional
from app.schemas.weather import WeatherData, WeatherResponse
from app.core.logging_config import get_logger

logger = get_logger(__name__)

# Open-Meteo API base URL (free, no API key required)
OPEN_METEO_BASE_URL = "https://api.open-meteo.com/v1"


class WeatherService:
    """Service for fetching weather data from Open-Meteo API"""
    
    @staticmethod
    async def get_weather_for_location(
        latitude: float,
        longitude: float,
        target_datetime: datetime,
    ) -> WeatherResponse:
        """
        Fetch weather data for a specific location and time.
        
        Uses Open-Meteo API which provides:
        - Historical weather data (up to a few days ago)
        - Current weather data
        - Forecast data (up to 16 days in future)
        
        Args:
            latitude: Location latitude (-90 to 90)
            longitude: Location longitude (-180 to 180)
            target_datetime: The date and time for which to get weather
            
        Returns:
            WeatherResponse with weather data or error
        """
        try:
            now = datetime.now()
            target_date = target_datetime.date()
            now_date = now.date()
            
            # Determine if we need historical data or forecast
            days_diff = (target_date - now_date).days
            
            logger.info(
                "Fetching weather data",
                extra={
                    "event": "weather_fetch",
                    "latitude": latitude,
                    "longitude": longitude,
                    "target_datetime": target_datetime.isoformat(),
                    "days_diff": days_diff,
                }
            )
            
            if days_diff < -92:
                # More than ~3 months in the past - historical archive
                weather_data = await WeatherService._fetch_historical_archive(
                    latitude, longitude, target_datetime
                )
            elif days_diff < -7:
                # More than 7 days in the past - use historical API
                weather_data = await WeatherService._fetch_historical(
                    latitude, longitude, target_datetime
                )
            elif days_diff <= 16:
                # Within forecast range (including past 7 days and future 16 days)
                weather_data = await WeatherService._fetch_forecast(
                    latitude, longitude, target_datetime
                )
            else:
                # Too far in the future
                return WeatherResponse(
                    success=False,
                    error="Wetterdaten für mehr als 16 Tage in der Zukunft nicht verfügbar"
                )
            
            if weather_data:
                logger.info(
                    "Weather data fetched successfully",
                    extra={
                        "event": "weather_fetch_success",
                        "temperature": weather_data.temperature_celsius,
                        "wind_speed": weather_data.wind_speed_kmh,
                    }
                )
                return WeatherResponse(weather=weather_data, success=True)
            else:
                return WeatherResponse(
                    success=False,
                    error="Keine Wetterdaten für diesen Zeitpunkt verfügbar"
                )
                
        except httpx.HTTPError as e:
            logger.error(
                "HTTP error fetching weather",
                extra={"event": "weather_fetch_http_error", "error": str(e)}
            )
            return WeatherResponse(success=False, error=f"HTTP Fehler: {str(e)}")
        except Exception as e:
            logger.error(
                "Error fetching weather",
                extra={"event": "weather_fetch_error", "error": str(e)},
                exc_info=True
            )
            return WeatherResponse(success=False, error=f"Fehler: {str(e)}")
    
    @staticmethod
    async def _fetch_forecast(
        latitude: float,
        longitude: float,
        target_datetime: datetime,
    ) -> Optional[WeatherData]:
        """Fetch weather from forecast API (covers past 7 days and future 16 days)"""
        
        # Request hourly data for the target date
        target_date_str = target_datetime.strftime("%Y-%m-%d")
        
        params = {
            "latitude": latitude,
            "longitude": longitude,
            "hourly": "temperature_2m,relative_humidity_2m,surface_pressure,cloud_cover,visibility,weather_code,wind_speed_10m,wind_direction_10m,wind_gusts_10m",
            "start_date": target_date_str,
            "end_date": target_date_str,
            "timezone": "auto",
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{OPEN_METEO_BASE_URL}/forecast",
                params=params,
                timeout=10.0
            )
            response.raise_for_status()
            data = response.json()
        
        return WeatherService._extract_hourly_weather(data, target_datetime)
    
    @staticmethod
    async def _fetch_historical(
        latitude: float,
        longitude: float,
        target_datetime: datetime,
    ) -> Optional[WeatherData]:
        """Fetch weather from historical API (past 7-92 days)"""
        
        target_date_str = target_datetime.strftime("%Y-%m-%d")
        
        params = {
            "latitude": latitude,
            "longitude": longitude,
            "hourly": "temperature_2m,relative_humidity_2m,surface_pressure,cloud_cover,visibility,weather_code,wind_speed_10m,wind_direction_10m,wind_gusts_10m",
            "start_date": target_date_str,
            "end_date": target_date_str,
            "timezone": "auto",
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{OPEN_METEO_BASE_URL}/forecast",
                params=params,
                timeout=10.0
            )
            response.raise_for_status()
            data = response.json()
        
        return WeatherService._extract_hourly_weather(data, target_datetime)
    
    @staticmethod
    async def _fetch_historical_archive(
        latitude: float,
        longitude: float,
        target_datetime: datetime,
    ) -> Optional[WeatherData]:
        """Fetch weather from historical archive API (data older than ~3 months)"""
        
        target_date_str = target_datetime.strftime("%Y-%m-%d")
        
        params = {
            "latitude": latitude,
            "longitude": longitude,
            "hourly": "temperature_2m,relative_humidity_2m,surface_pressure,cloud_cover,visibility,weather_code,wind_speed_10m,wind_direction_10m,wind_gusts_10m",
            "start_date": target_date_str,
            "end_date": target_date_str,
            "timezone": "auto",
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.get(
                "https://archive-api.open-meteo.com/v1/archive",
                params=params,
                timeout=10.0
            )
            response.raise_for_status()
            data = response.json()
        
        return WeatherService._extract_hourly_weather(data, target_datetime)
    
    @staticmethod
    def _extract_hourly_weather(
        api_response: dict,
        target_datetime: datetime,
    ) -> Optional[WeatherData]:
        """Extract weather data for the specific hour from API response"""
        
        hourly = api_response.get("hourly", {})
        times = hourly.get("time", [])
        
        if not times:
            return None
        
        # Find the closest hour to target time
        target_hour = target_datetime.hour
        
        # Try to find exact hour match
        best_index = None
        for i, time_str in enumerate(times):
            # Parse the time string (format: "2024-01-15T14:00")
            try:
                time_dt = datetime.fromisoformat(time_str)
                if time_dt.hour == target_hour:
                    best_index = i
                    break
            except ValueError:
                continue
        
        # If no exact match, use the first available hour
        if best_index is None and times:
            best_index = 0
        
        if best_index is None:
            return None
        
        # Extract weather data at this index
        def safe_get(key: str, index: int):
            values = hourly.get(key, [])
            if index < len(values):
                return values[index]
            return None
        
        temperature = safe_get("temperature_2m", best_index)
        humidity = safe_get("relative_humidity_2m", best_index)
        pressure = safe_get("surface_pressure", best_index)
        cloud_cover = safe_get("cloud_cover", best_index)
        visibility = safe_get("visibility", best_index)
        weather_code = safe_get("weather_code", best_index)
        wind_speed = safe_get("wind_speed_10m", best_index)
        wind_direction = safe_get("wind_direction_10m", best_index)
        wind_gusts = safe_get("wind_gusts_10m", best_index)
        
        # Convert visibility from meters to kilometers
        visibility_km = visibility / 1000.0 if visibility is not None else None
        
        # Get weather description from code
        weather_description = WeatherData.get_weather_description_from_code(weather_code)
        
        return WeatherData(
            temperature_celsius=temperature,
            wind_speed_kmh=wind_speed,
            wind_direction_degrees=int(wind_direction) if wind_direction is not None else None,
            wind_gusts_kmh=wind_gusts,
            weather_code=weather_code,
            weather_description=weather_description,
            humidity_percent=int(humidity) if humidity is not None else None,
            pressure_hpa=pressure,
            cloud_cover_percent=int(cloud_cover) if cloud_cover is not None else None,
            visibility_km=visibility_km,
        )

