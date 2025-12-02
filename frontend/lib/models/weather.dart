/// Weather data model for jump weather conditions
class WeatherData {
  final double? temperatureCelsius;
  final double? windSpeedKmh;
  final int? windDirectionDegrees;
  final double? windGustsKmh;
  final int? weatherCode;
  final String? weatherDescription;
  final int? humidityPercent;
  final double? pressureHpa;
  final int? cloudCoverPercent;
  final double? visibilityKm;

  WeatherData({
    this.temperatureCelsius,
    this.windSpeedKmh,
    this.windDirectionDegrees,
    this.windGustsKmh,
    this.weatherCode,
    this.weatherDescription,
    this.humidityPercent,
    this.pressureHpa,
    this.cloudCoverPercent,
    this.visibilityKm,
  });

  /// Get wind direction as compass direction (N, NE, E, etc.)
  String? get windDirectionName {
    if (windDirectionDegrees == null) return null;
    const directions = [
      'N', 'NNO', 'NO', 'ONO', 'O', 'OSO', 'SO', 'SSO',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'
    ];
    final index = ((windDirectionDegrees! / 22.5).round()) % 16;
    return directions[index];
  }

  /// Check if we have any weather data
  bool get hasData =>
      temperatureCelsius != null ||
      windSpeedKmh != null ||
      windDirectionDegrees != null ||
      weatherCode != null;

  /// Check if we have wind data
  bool get hasWindData =>
      windSpeedKmh != null || windDirectionDegrees != null;

  Map<String, dynamic> toMap() {
    return {
      'temperature_celsius': temperatureCelsius,
      'wind_speed_kmh': windSpeedKmh,
      'wind_direction_degrees': windDirectionDegrees,
      'wind_gusts_kmh': windGustsKmh,
      'weather_code': weatherCode,
      'weather_description': weatherDescription,
      'humidity_percent': humidityPercent,
      'pressure_hpa': pressureHpa,
      'cloud_cover_percent': cloudCoverPercent,
      'visibility_km': visibilityKm,
    };
  }

  factory WeatherData.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return WeatherData();

    return WeatherData(
      temperatureCelsius: _parseDouble(map['temperature_celsius']),
      windSpeedKmh: _parseDouble(map['wind_speed_kmh']),
      windDirectionDegrees: _parseInt(map['wind_direction_degrees']),
      windGustsKmh: _parseDouble(map['wind_gusts_kmh']),
      weatherCode: _parseInt(map['weather_code']),
      weatherDescription: map['weather_description'] as String?,
      humidityPercent: _parseInt(map['humidity_percent']),
      pressureHpa: _parseDouble(map['pressure_hpa']),
      cloudCoverPercent: _parseInt(map['cloud_cover_percent']),
      visibilityKm: _parseDouble(map['visibility_km']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  WeatherData copyWith({
    double? temperatureCelsius,
    double? windSpeedKmh,
    int? windDirectionDegrees,
    double? windGustsKmh,
    int? weatherCode,
    String? weatherDescription,
    int? humidityPercent,
    double? pressureHpa,
    int? cloudCoverPercent,
    double? visibilityKm,
  }) {
    return WeatherData(
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      windSpeedKmh: windSpeedKmh ?? this.windSpeedKmh,
      windDirectionDegrees: windDirectionDegrees ?? this.windDirectionDegrees,
      windGustsKmh: windGustsKmh ?? this.windGustsKmh,
      weatherCode: weatherCode ?? this.weatherCode,
      weatherDescription: weatherDescription ?? this.weatherDescription,
      humidityPercent: humidityPercent ?? this.humidityPercent,
      pressureHpa: pressureHpa ?? this.pressureHpa,
      cloudCoverPercent: cloudCoverPercent ?? this.cloudCoverPercent,
      visibilityKm: visibilityKm ?? this.visibilityKm,
    );
  }
}

