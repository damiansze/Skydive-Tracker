import 'freefall_stats.dart';
import 'weather.dart';

enum JumpType {
  TANDEM,
  SOLO,
  AFF,
  STATIC_LINE,
  WINGSUIT,
  OTHER,
}

extension JumpTypeExtension on JumpType {
  String get displayName {
    switch (this) {
      case JumpType.TANDEM:
        return 'Tandem';
      case JumpType.SOLO:
        return 'Solo';
      case JumpType.AFF:
        return 'AFF';
      case JumpType.STATIC_LINE:
        return 'Static Line';
      case JumpType.WINGSUIT:
        return 'Wingsuit';
      case JumpType.OTHER:
        return 'Sonstiges';
    }
  }
}

enum JumpMethod {
  PLANE,
  HELICOPTER,
  BASE,
  BALLOON,
  OTHER,
}

extension JumpMethodExtension on JumpMethod {
  String get displayName {
    switch (this) {
      case JumpMethod.PLANE:
        return 'Flugzeug';
      case JumpMethod.HELICOPTER:
        return 'Helikopter';
      case JumpMethod.BASE:
        return 'BASE Jump';
      case JumpMethod.BALLOON:
        return 'Ballon';
      case JumpMethod.OTHER:
        return 'Sonstiges';
    }
  }
}

class Jump {
  final String id;
  final DateTime date;
  final String location;
  final double? latitude;
  final double? longitude;
  final int altitude;
  final JumpType? jumpType;
  final JumpMethod? jumpMethod;
  final List<String> equipmentIds;
  final String? notes;
  final DateTime createdAt;
  final FreefallStats? freefallStats;
  final WeatherData? weather;

  Jump({
    required this.id,
    required this.date,
    required this.location,
    this.latitude,
    this.longitude,
    required this.altitude,
    this.jumpType,
    this.jumpMethod,
    this.equipmentIds = const [],
    this.notes,
    required this.createdAt,
    this.freefallStats,
    this.weather,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'jump_type': jumpType?.toString().split('.').last.toLowerCase(),
      'jump_method': jumpMethod?.toString().split('.').last.toLowerCase(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'freefall_stats': freefallStats?.toMap(),
      'weather': weather?.toMap(),
    };
  }

  static FreefallStats? _parseFreefallStats(dynamic freefallStatsData) {
    if (freefallStatsData == null) {
      return null;
    }
    
    // Handle different formats: Map, dict, or already parsed
    Map<String, dynamic>? freefallMap;
    if (freefallStatsData is Map<String, dynamic>) {
      freefallMap = freefallStatsData;
    } else if (freefallStatsData is Map) {
      // Convert Map<dynamic, dynamic> to Map<String, dynamic>
      freefallMap = Map<String, dynamic>.from(freefallStatsData);
    } else {
      return null;
    }
    
    return FreefallStats.fromMap(freefallMap);
  }

  static WeatherData? _parseWeatherData(dynamic weatherData) {
    if (weatherData == null) {
      return null;
    }
    
    // Handle different formats: Map, dict, or already parsed
    Map<String, dynamic>? weatherMap;
    if (weatherData is Map<String, dynamic>) {
      weatherMap = weatherData;
    } else if (weatherData is Map) {
      // Convert Map<dynamic, dynamic> to Map<String, dynamic>
      weatherMap = Map<String, dynamic>.from(weatherData);
    } else {
      return null;
    }
    
    return WeatherData.fromMap(weatherMap);
  }

  factory Jump.fromMap(Map<String, dynamic> map) {
    // Handle equipment_ids from backend
    List<String> equipmentIds = [];
    if (map['equipment_ids'] != null) {
      equipmentIds = List<String>.from(map['equipment_ids'] as List);
    }
    
    // Handle jump_type from backend
    JumpType? jumpType;
    if (map['jump_type'] != null) {
      final typeString = map['jump_type'].toString().toLowerCase();
      try {
        jumpType = JumpType.values.firstWhere(
          (e) => e.toString().split('.').last.toLowerCase() == typeString,
        );
      } catch (e) {
        jumpType = null;
      }
    }
    
    // Handle jump_method from backend
    JumpMethod? jumpMethod;
    if (map['jump_method'] != null) {
      final methodString = map['jump_method'].toString().toLowerCase();
      try {
        jumpMethod = JumpMethod.values.firstWhere(
          (e) => e.toString().split('.').last.toLowerCase() == methodString,
        );
      } catch (e) {
        jumpMethod = null;
      }
    }
    
    final freefallStats = _parseFreefallStats(map['freefall_stats']);
    final weather = _parseWeatherData(map['weather']);
    
    return Jump(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      location: map['location'] as String,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      altitude: map['altitude'] as int,
      jumpType: jumpType,
      jumpMethod: jumpMethod,
      equipmentIds: equipmentIds,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      freefallStats: freefallStats,
      weather: weather,
    );
  }

  Jump copyWith({
    String? id,
    DateTime? date,
    String? location,
    double? latitude,
    double? longitude,
    int? altitude,
    JumpType? jumpType,
    JumpMethod? jumpMethod,
    List<String>? equipmentIds,
    String? notes,
    DateTime? createdAt,
    FreefallStats? freefallStats,
    WeatherData? weather,
  }) {
    return Jump(
      id: id ?? this.id,
      date: date ?? this.date,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      jumpType: jumpType ?? this.jumpType,
      jumpMethod: jumpMethod ?? this.jumpMethod,
      equipmentIds: equipmentIds ?? this.equipmentIds,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      freefallStats: freefallStats ?? this.freefallStats,
      weather: weather ?? this.weather,
    );
  }
}
