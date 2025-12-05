import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_skydive_tracker/models/weather.dart';

void main() {
  group('WeatherData Model Tests', () {
    test('WeatherData fromMap creates correct object', () {
      final map = {
        'temperature_celsius': 15.5,
        'wind_speed_kmh': 12.0,
        'wind_direction_degrees': 180,
        'humidity_percent': 65,
        'pressure_hpa': 1013.25,
        'cloud_cover_percent': 25,
        'visibility_km': 15.0,
      };

      final weatherData = WeatherData.fromMap(map);

      expect(weatherData.temperatureCelsius, 15.5);
      expect(weatherData.windSpeedKmh, 12.0);
      expect(weatherData.windDirectionDegrees, 180);
      expect(weatherData.humidityPercent, 65);
      expect(weatherData.pressureHpa, 1013.25);
      expect(weatherData.cloudCoverPercent, 25);
      expect(weatherData.visibilityKm, 15.0);
    });

    test('WeatherData toMap returns correct map', () {
      final weatherData = WeatherData(
        temperatureCelsius: 15.5,
        windSpeedKmh: 12.0,
        windDirectionDegrees: 180,
        humidityPercent: 65,
        pressureHpa: 1013.25,
        cloudCoverPercent: 25,
        visibilityKm: 15.0,
      );

      final map = weatherData.toMap();

      expect(map['temperature_celsius'], 15.5);
      expect(map['wind_speed_kmh'], 12.0);
      expect(map['wind_direction_degrees'], 180);
      expect(map['humidity_percent'], 65);
      expect(map['pressure_hpa'], 1013.25);
      expect(map['cloud_cover_percent'], 25);
      expect(map['visibility_km'], 15.0);
    });

    test('WeatherData properties are calculated correctly', () {
      final weatherData = WeatherData(
        temperatureCelsius: 20.5,
        windSpeedKmh: 15.0,
        windDirectionDegrees: 270,
        humidityPercent: 60,
        pressureHpa: 1013.0,
        cloudCoverPercent: 40,
        visibilityKm: 10.0,
      );

      expect(weatherData.windDirectionName, 'W');
      expect(weatherData.hasData, true);
      expect(weatherData.hasWindData, true);
    });

    test('WeatherData wind direction name conversion works', () {
      final weather0 = WeatherData(temperatureCelsius: 20.0, windDirectionDegrees: 0);
      final weather45 = WeatherData(temperatureCelsius: 20.0, windDirectionDegrees: 45);
      final weather90 = WeatherData(temperatureCelsius: 20.0, windDirectionDegrees: 90);
      final weather135 = WeatherData(temperatureCelsius: 20.0, windDirectionDegrees: 135);
      final weather180 = WeatherData(temperatureCelsius: 20.0, windDirectionDegrees: 180);
      final weather225 = WeatherData(temperatureCelsius: 20.0, windDirectionDegrees: 225);
      final weather270 = WeatherData(temperatureCelsius: 20.0, windDirectionDegrees: 270);
      final weather315 = WeatherData(temperatureCelsius: 20.0, windDirectionDegrees: 315);

      expect(weather0.windDirectionName, 'N');
      expect(weather45.windDirectionName, 'NO');
      expect(weather90.windDirectionName, 'O');
      expect(weather135.windDirectionName, 'SO');
      expect(weather180.windDirectionName, 'S');
      expect(weather225.windDirectionName, 'SW');
      expect(weather270.windDirectionName, 'W');
      expect(weather315.windDirectionName, 'NW');
    });

    test('WeatherData copyWith works correctly', () {
      final original = WeatherData(
        temperatureCelsius: 20.0,
        windSpeedKmh: 10.0,
      );

      final copied = original.copyWith(
        temperatureCelsius: 25.0,
        humidityPercent: 70,
      );

      expect(copied.temperatureCelsius, 25.0);
      expect(copied.windSpeedKmh, 10.0); // Unchanged
      expect(copied.humidityPercent, 70); // New value
    });

    test('WeatherData handles null values correctly', () {
      final weatherData = WeatherData();

      expect(weatherData.temperatureCelsius, isNull);
      expect(weatherData.windDirectionName, isNull);
      expect(weatherData.hasData, false);
      expect(weatherData.hasWindData, false);
    });
  });
}