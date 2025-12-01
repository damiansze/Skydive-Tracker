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
    if (map == null) return FreefallStats();
    
    return FreefallStats(
      freefallDurationSeconds: map['freefall_duration_seconds'] as double?,
      maxVerticalVelocityMs: map['max_vertical_velocity_ms'] as double?,
      exitTime: map['exit_time'] != null 
          ? DateTime.parse(map['exit_time'] as String)
          : null,
      deploymentTime: map['deployment_time'] != null
          ? DateTime.parse(map['deployment_time'] as String)
          : null,
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
