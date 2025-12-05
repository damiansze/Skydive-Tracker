import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_skydive_tracker/models/jump.dart';
import 'package:flutter_skydive_tracker/models/freefall_stats.dart';
import 'package:flutter_skydive_tracker/models/weather.dart';

void main() {
  group('Jump Model Tests', () {
    test('Jump.fromMap creates correct Jump object', () {
      final map = {
        'id': '123',
        'date': '2024-01-15T14:30:00.000Z',
        'location': 'Interlaken',
        'latitude': 46.6863,
        'longitude': 7.8632,
        'altitude': 12000,
        'jump_type': 'solo',
        'notes': 'Great jump!',
        'created_at': '2024-01-15T14:25:00.000Z',
        'freefall_stats': {
          'freefall_duration_seconds': 45.5,
          'max_vertical_velocity_ms': 55.0,
          'exit_time': '2024-01-15T14:30:15.000Z',
          'deployment_time': '2024-01-15T14:31:00.000Z',
        },
        'weather': {
          'temperature_celsius': 15.5,
          'wind_speed_kmh': 12.0,
          'wind_direction_degrees': 180,
          'humidity_percent': 65,
        },
      };

      final jump = Jump.fromMap(map);

      expect(jump.id, '123');
      expect(jump.date.year, 2024);
      expect(jump.date.month, 1);
      expect(jump.date.day, 15);
      expect(jump.location, 'Interlaken');
      expect(jump.latitude, 46.6863);
      expect(jump.longitude, 7.8632);
      expect(jump.altitude, 12000);
      expect(jump.jumpType, JumpType.SOLO);
      expect(jump.notes, 'Great jump!');
      expect(jump.freefallStats?.freefallDurationSeconds, 45.5);
      expect(jump.freefallStats?.maxVerticalVelocityMs, 55.0);
      expect(jump.weather?.temperatureCelsius, 15.5);
      expect(jump.weather?.windSpeedKmh, 12.0);
    });

    test('Jump.toMap returns correct map', () {
      final jump = Jump(
        id: '123',
        date: DateTime(2024, 1, 15, 14, 30),
        location: 'Interlaken',
        latitude: 46.6863,
        longitude: 7.8632,
        altitude: 12000,
        jumpType: JumpType.SOLO,
        notes: 'Great jump!',
        createdAt: DateTime(2024, 1, 15, 14, 25),
        freefallStats: FreefallStats(
          freefallDurationSeconds: 45.5,
          maxVerticalVelocityMs: 55.0,
          exitTime: DateTime(2024, 1, 15, 14, 30, 15),
          deploymentTime: DateTime(2024, 1, 15, 14, 31),
        ),
        weather: WeatherData(
          temperatureCelsius: 15.5,
          windSpeedKmh: 12.0,
          windDirectionDegrees: 180,
          humidityPercent: 65,
        ),
      );

      final map = jump.toMap();

      expect(map['id'], '123');
      expect(map['location'], 'Interlaken');
      expect(map['altitude'], 12000);
      expect(map['jump_type'], 'solo');
      expect(map['freefall_stats']['freefall_duration_seconds'], 45.5);
      expect(map['weather']['temperature_celsius'], 15.5);
    });

    test('JumpType enum values are correct', () {
      expect(JumpType.SOLO.displayName, 'Solo');
      expect(JumpType.TANDEM.displayName, 'Tandem');
      expect(JumpType.AFF.displayName, 'AFF');
      expect(JumpType.STATIC_LINE.displayName, 'Static Line');
      expect(JumpType.WINGSUIT.displayName, 'Wingsuit');
      expect(JumpType.OTHER.displayName, 'Sonstiges');
    });

    test('Jump validation works', () {
      // Valid jump
      final validJump = Jump(
        id: '123',
        date: DateTime.now(),
        location: 'Test Location',
        latitude: 0.0,
        longitude: 0.0,
        altitude: 4000,
        jumpType: JumpType.SOLO,
        createdAt: DateTime.now(),
      );

      expect(validJump.id, isNotNull);
      expect(validJump.location, isNotEmpty);

      // Jump with empty location should still be valid (manual entry)
      final jumpWithEmptyLocation = Jump(
        id: '124',
        date: DateTime.now(),
        location: '',
        latitude: null,
        longitude: null,
        altitude: 4000,
        jumpType: JumpType.SOLO,
        createdAt: DateTime.now(),
      );

      expect(jumpWithEmptyLocation.location, '');
    });
  });
}
