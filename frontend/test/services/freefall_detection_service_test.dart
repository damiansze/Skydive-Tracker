import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_skydive_tracker/models/freefall_stats.dart';

void main() {
  group('FreefallStats Model Tests', () {
    test('FreefallStats can be created with valid data', () {
      final stats = FreefallStats(
        freefallDurationSeconds: 45.5,
        maxVerticalVelocityMs: 55.0,
        exitTime: DateTime(2024, 1, 15, 14, 30, 15),
        deploymentTime: DateTime(2024, 1, 15, 14, 31, 0),
      );

      expect(stats.freefallDurationSeconds, 45.5);
      expect(stats.maxVerticalVelocityMs, 55.0);
      expect(stats.maxVerticalVelocityKmh, 55.0 * 3.6); // Conversion to km/h
      expect(stats.exitTime, isNotNull);
      expect(stats.deploymentTime, isNotNull);
    });

    test('FreefallStats handles null values', () {
      final stats = FreefallStats(
        freefallDurationSeconds: null,
        maxVerticalVelocityMs: 55.0,
        exitTime: DateTime.now(),
        deploymentTime: null,
      );

      expect(stats.freefallDurationSeconds, isNull);
      expect(stats.maxVerticalVelocityMs, 55.0);
      expect(stats.deploymentTime, isNull);
    });

    test('FreefallStats copyWith works correctly', () {
      final original = FreefallStats(
        freefallDurationSeconds: 45.0,
        maxVerticalVelocityMs: 50.0,
        exitTime: DateTime(2024, 1, 15, 14, 30),
        deploymentTime: DateTime(2024, 1, 15, 14, 31),
      );

      final copied = original.copyWith(
        freefallDurationSeconds: 60.0,
        maxVerticalVelocityMs: 60.0,
      );

      expect(copied.freefallDurationSeconds, 60.0);
      expect(copied.maxVerticalVelocityMs, 60.0);
      expect(copied.exitTime, original.exitTime); // Unchanged
      expect(copied.deploymentTime, original.deploymentTime); // Unchanged
    });

    test('FreefallStats velocity conversion is correct', () {
      final stats = FreefallStats(
        freefallDurationSeconds: 45.0,
        maxVerticalVelocityMs: 55.8, // ~200 km/h
        exitTime: DateTime.now(),
        deploymentTime: DateTime.now().add(const Duration(seconds: 45)),
      );

      // 55.8 m/s * 3.6 = 200.88 km/h
      expect(stats.maxVerticalVelocityKmh, closeTo(200.88, 0.01));
    });
  });
}