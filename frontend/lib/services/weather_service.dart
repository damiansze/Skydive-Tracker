import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';
import '../config/api_config.dart';

/// Service for fetching weather data
class WeatherService {
  static String get baseUrl => ApiConfig.baseUrl;

  /// Fetch weather data for a specific location and time
  /// 
  /// [latitude] Location latitude (-90 to 90)
  /// [longitude] Location longitude (-180 to 180)
  /// [dateTime] The date and time for which to get weather
  /// 
  /// Returns WeatherData if successful, null if failed
  static Future<WeatherData?> getWeather({
    required double latitude,
    required double longitude,
    required DateTime dateTime,
  }) async {
    try {
      final url = '$baseUrl/weather/';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'latitude': latitude,
          'longitude': longitude,
          'datetime': dateTime.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        if (data['success'] == true && data['weather'] != null) {
          return WeatherData.fromMap(data['weather'] as Map<String, dynamic>);
        }
        
        // Log error if present
        if (data['error'] != null) {
          print('Weather API error: ${data['error']}');
        }
        return null;
      } else {
        print('Weather API HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching weather: $e');
      return null;
    }
  }
}


