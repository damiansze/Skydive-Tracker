"""Weather service for fetching weather data from Open-Meteo API"""
import httpx
from datetime import datetime, timedelta
from typing import Optional
from app.schemas.weather import WeatherData, WeatherResponse
from app.core.logging_config import get_logger

logger = get_logger(__name__)

# Open-Meteo API base URLs (free, no API key required)
OPEN_METEO_FORECAST_URL = "https://api.open-meteo.com/v1/forecast"
OPEN_METEO_ARCHIVE_URL = "https://archive-api.open-meteo.com/v1/archive"

# Variables available in forecast API
FORECAST_HOURLY_VARS = "temperature_2m,relative_humidity_2m,surface_pressure,cloud_cover,visibility,weather_code,wind_speed_10m,wind_direction_10m,wind_gusts_10m"

# Variables available in historical archive API (visibility NOT available)
ARCHIVE_HOURLY_VARS = "temperature_2m,relative_humidity_2m,surface_pressure,cloud_cover,weather_code,wind_speed_10m,wind_direction_10m,wind_gusts_10m"


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
        - Historical weather data (from 1940 onwards via archive API)
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
                    "target_date": str(target_date),
                    "target_hour": target_datetime.hour,
                    "target_minute": target_datetime.minute,
                    "days_diff": days_diff,
                    "has_tzinfo": target_datetime.tzinfo is not None,
                }
            )
            
            if days_diff < -5:
                # More than 5 days in the past - use historical archive API
                # Archive API has data from 1940 onwards
                weather_data = await WeatherService._fetch_historical_archive(
                    latitude, longitude, target_datetime
                )
            elif days_diff <= 16:
                # Within forecast range (past 5 days to future 16 days)
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
                        "wind_direction": weather_data.wind_direction_degrees,
                    }
                )
                return WeatherResponse(weather=weather_data, success=True)
            else:
                return WeatherResponse(
                    success=False,
                    error="Keine Wetterdaten für diesen Zeitpunkt verfügbar"
                )
                
        except httpx.HTTPStatusError as e:
            logger.error(
                "HTTP status error fetching weather",
                extra={
                    "event": "weather_fetch_http_error", 
                    "error": str(e),
                    "status_code": e.response.status_code,
                    "response_text": e.response.text[:500] if e.response.text else None,
                }
            )
            return WeatherResponse(success=False, error=f"HTTP Fehler {e.response.status_code}: API nicht erreichbar")
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
        """Fetch weather from forecast API (covers past ~5 days and future 16 days)"""
        
        target_date_str = target_datetime.strftime("%Y-%m-%d")
        
        params = {
            "latitude": latitude,
            "longitude": longitude,
            "hourly": FORECAST_HOURLY_VARS,
            "start_date": target_date_str,
            "end_date": target_date_str,
            "timezone": "auto",
        }
        
        logger.info(
            "Fetching from forecast API",
            extra={
                "event": "weather_fetch_forecast",
                "url": OPEN_METEO_FORECAST_URL,
                "params": params,
            }
        )
        
        async with httpx.AsyncClient() as client:
            response = await client.get(
                OPEN_METEO_FORECAST_URL,
                params=params,
                timeout=15.0
            )
            response.raise_for_status()
            data = await response.json()
        
        # Log the timezone info from API response
        logger.info(
            "Forecast API response",
            extra={
                "event": "weather_forecast_response",
                "timezone": data.get("timezone"),
                "timezone_abbreviation": data.get("timezone_abbreviation"),
                "utc_offset_seconds": data.get("utc_offset_seconds"),
                "times_count": len(data.get("hourly", {}).get("time", [])),
            }
        )
        
        return WeatherService._extract_hourly_weather(data, target_datetime, has_visibility=True)
    
    @staticmethod
    async def _fetch_historical_archive(
        latitude: float,
        longitude: float,
        target_datetime: datetime,
    ) -> Optional[WeatherData]:
        """Fetch weather from historical archive API (data from 1940 onwards)"""
        
        target_date_str = target_datetime.strftime("%Y-%m-%d")
        
        params = {
            "latitude": latitude,
            "longitude": longitude,
            "hourly": ARCHIVE_HOURLY_VARS,
            "start_date": target_date_str,
            "end_date": target_date_str,
            "timezone": "auto",
        }
        
        logger.info(
            "Fetching from historical archive API",
            extra={
                "event": "weather_fetch_archive",
                "url": OPEN_METEO_ARCHIVE_URL,
                "params": params,
            }
        )
        
        async with httpx.AsyncClient() as client:
            response = await client.get(
                OPEN_METEO_ARCHIVE_URL,
                params=params,
                timeout=15.0
            )
            response.raise_for_status()
            data = await response.json()
        
        logger.info(
            "Archive API response received",
            extra={
                "event": "weather_archive_response",
                "timezone": data.get("timezone"),
                "timezone_abbreviation": data.get("timezone_abbreviation"),
                "utc_offset_seconds": data.get("utc_offset_seconds"),
                "has_hourly": "hourly" in data,
                "hourly_keys": list(data.get("hourly", {}).keys()) if "hourly" in data else [],
            }
        )
        
        return WeatherService._extract_hourly_weather(data, target_datetime, has_visibility=False)
    
    @staticmethod
    def _extract_hourly_weather(
        api_response: dict,
        target_datetime: datetime,
        has_visibility: bool = True,
    ) -> Optional[WeatherData]:
        """Extract weather data for the specific hour from API response"""
        
        hourly = api_response.get("hourly", {})
        times = hourly.get("time", [])
        
        if not times:
            logger.warning(
                "No time data in API response",
                extra={
                    "event": "weather_no_times",
                    "response_keys": list(api_response.keys()),
                    "hourly_keys": list(hourly.keys()) if hourly else [],
                }
            )
            return None
        
        # Get target hour from the datetime
        target_hour = target_datetime.hour
        
        # Log available times for debugging
        logger.info(
            "Searching for matching hour",
            extra={
                "event": "weather_hour_search",
                "target_hour": target_hour,
                "available_times_sample": times[:3] if len(times) >= 3 else times,
                "total_times": len(times),
            }
        )
        
        # Try to find exact hour match
        best_index = None
        matched_time = None
        for i, time_str in enumerate(times):
            # Parse the time string (format: "2024-01-15T14:00")
            try:
                time_dt = datetime.fromisoformat(time_str)
                if time_dt.hour == target_hour:
                    best_index = i
                    matched_time = time_str
                    break
            except ValueError:
                continue
        
        # If no exact match, use the first available hour (noon as fallback)
        if best_index is None and times:
            # Try to find noon (12:00) as a reasonable default
            for i, time_str in enumerate(times):
                try:
                    time_dt = datetime.fromisoformat(time_str)
                    if time_dt.hour == 12:
                        best_index = i
                        matched_time = time_str
                        break
                except ValueError:
                    continue
            # If still no match, use first available
            if best_index is None:
                best_index = 0
                matched_time = times[0]
        
        if best_index is None:
            return None
        
        logger.info(
            "Found matching time slot",
            extra={
                "event": "weather_time_matched",
                "target_hour": target_hour,
                "matched_time": matched_time,
                "matched_index": best_index,
            }
        )
        
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
        weather_code = safe_get("weather_code", best_index)
        wind_speed = safe_get("wind_speed_10m", best_index)
        wind_direction = safe_get("wind_direction_10m", best_index)
        wind_gusts = safe_get("wind_gusts_10m", best_index)
        
        # Visibility only available in forecast API
        visibility = safe_get("visibility", best_index) if has_visibility else None
        visibility_km = visibility / 1000.0 if visibility is not None else None
        
        # Get weather description from code
        weather_description = WeatherData.get_weather_description_from_code(weather_code)
        
        logger.info(
            "Extracted weather data",
            extra={
                "event": "weather_extracted",
                "matched_time": matched_time,
                "index": best_index,
                "temperature": temperature,
                "wind_speed": wind_speed,
                "wind_direction": wind_direction,
                "wind_gusts": wind_gusts,
                "weather_code": weather_code,
                "humidity": humidity,
                "pressure": pressure,
                "cloud_cover": cloud_cover,
            }
        )
        
        # Normalize wind direction: 360° = 0° (both are North)
        wind_direction_normalized = None
        if wind_direction is not None:
            wind_direction_int = int(wind_direction)
            # Normalize 360 to 0 (both mean North)
            wind_direction_normalized = wind_direction_int % 360
        
        return WeatherData(
            temperature_celsius=temperature,
            wind_speed_kmh=wind_speed,
            wind_direction_degrees=wind_direction_normalized,
            wind_gusts_kmh=wind_gusts,
            weather_code=weather_code,
            weather_description=weather_description,
            humidity_percent=int(humidity) if humidity is not None else None,
            pressure_hpa=pressure,
            cloud_cover_percent=int(cloud_cover) if cloud_cover is not None else None,
            visibility_km=visibility_km,
        )
