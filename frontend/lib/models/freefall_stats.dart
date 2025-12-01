class FreefallStats {
  final double? freefallDurationSeconds; // Duration in seconds
  final double? maxVerticalVelocityMs; // Maximum velocity in m/s
  final DateTime? exitTime; // When freefall started
  final DateTime? deploymentTime; // When parachute opened

  FreefallStats({
    this.freefallDurationSeconds,
    this.maxVerticalVelocityMs,
    this.exitTime,
    this.deploymentTime,
  });

  // Convert m/s to km/h
  double? get maxVerticalVelocityKmh {
    if (maxVerticalVelocityMs == null) return null;
    return maxVerticalVelocityMs! * 3.6;
  }

  Map<String, dynamic> toMap() {
    return {
      'freefall_duration_seconds': freefallDurationSeconds,
      'max_vertical_velocity_ms': maxVerticalVelocityMs,
      'exit_time': exitTime?.toIso8601String(),
      'deployment_time': deploymentTime?.toIso8601String(),
    };
  }

  factory FreefallStats.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return FreefallStats();
    
    // Handle both string and DateTime objects
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }
    
    // Handle numeric values (int or double)
    double? parseDouble(dynamic value) {
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
    
    return FreefallStats(
      freefallDurationSeconds: parseDouble(map['freefall_duration_seconds']),
      maxVerticalVelocityMs: parseDouble(map['max_vertical_velocity_ms']),
      exitTime: parseDateTime(map['exit_time']),
      deploymentTime: parseDateTime(map['deployment_time']),
    );
  }

  FreefallStats copyWith({
    double? freefallDurationSeconds,
    double? maxVerticalVelocityMs,
    DateTime? exitTime,
    DateTime? deploymentTime,
  }) {
    return FreefallStats(
      freefallDurationSeconds: freefallDurationSeconds ?? this.freefallDurationSeconds,
      maxVerticalVelocityMs: maxVerticalVelocityMs ?? this.maxVerticalVelocityMs,
      exitTime: exitTime ?? this.exitTime,
      deploymentTime: deploymentTime ?? this.deploymentTime,
    );
  }

  bool get hasData => 
      freefallDurationSeconds != null || 
      maxVerticalVelocityMs != null ||
      exitTime != null ||
      deploymentTime != null;
}
