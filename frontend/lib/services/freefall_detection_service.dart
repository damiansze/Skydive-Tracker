import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/freefall_stats.dart';

/// Service for detecting freefall using device sensors
class FreefallDetectionService {
  static const bool useSimulatedSensors = bool.fromEnvironment('USE_SIMULATED_SENSORS', defaultValue: false);
  
  // Detection thresholds
  static const double exitAccelerationThreshold = 2.0; // m/s² - sudden acceleration change
  static const double freefallAccelerationThreshold = 0.5; // m/s² - near freefall (gravity ~9.8 m/s²)
  static const double deploymentDecelerationThreshold = 15.0; // m/s² - strong deceleration
  static const double minFreefallDuration = 1.0; // seconds - minimum freefall to be valid
  static const double maxFreefallDuration = 300.0; // seconds - maximum reasonable freefall
  
  // Sensor update intervals
  static const Duration sensorUpdateInterval = Duration(milliseconds: 100); // 10 Hz
  
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  
  DateTime? _exitTime;
  DateTime? _deploymentTime;
  double _maxVerticalVelocity = 0.0;
  List<SensorReading> _readings = [];
  bool _isDetecting = false;
  bool _inFreefall = false;
  
  final _statsController = StreamController<FreefallStats?>.broadcast();
  Stream<FreefallStats?> get statsStream => _statsController.stream;
  
  FreefallStats? _currentStats;
  
  /// Start freefall detection
  Future<void> startDetection() async {
    if (_isDetecting) return;
    
    _isDetecting = true;
    _exitTime = null;
    _deploymentTime = null;
    _maxVerticalVelocity = 0.0;
    _readings.clear();
    _inFreefall = false;
    _currentStats = null;
    
    if (useSimulatedSensors) {
      _startSimulatedDetection();
    } else {
      await _startRealSensorDetection();
    }
  }
  
  /// Stop freefall detection
  Future<void> stopDetection() async {
    _isDetecting = false;
    await _accelerometerSubscription?.cancel();
    await _gyroscopeSubscription?.cancel();
    await _magnetometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _magnetometerSubscription = null;
    
    // Calculate final stats if we have exit time
    if (_exitTime != null) {
      _calculateFinalStats();
    }
  }
  
  /// Get current freefall stats
  FreefallStats? getCurrentStats() => _currentStats;
  
  /// Reset detection state
  void reset() {
    _exitTime = null;
    _deploymentTime = null;
    _maxVerticalVelocity = 0.0;
    _readings.clear();
    _inFreefall = false;
    _currentStats = null;
  }
  
  // Real sensor detection
  Future<void> _startRealSensorDetection() async {
    try {
      // Accelerometer for vertical acceleration
      _accelerometerSubscription = accelerometerEventStream(
        samplingPeriod: sensorUpdateInterval,
      ).listen(_onAccelerometerEvent);
      
      // Gyroscope for rotation detection (optional, for better accuracy)
      _gyroscopeSubscription = gyroscopeEventStream(
        samplingPeriod: sensorUpdateInterval,
      ).listen(_onGyroscopeEvent);
      
    } catch (e) {
      print('Error starting sensors: $e');
      _isDetecting = false;
    }
  }
  
  void _onAccelerometerEvent(AccelerometerEvent event) {
    if (!_isDetecting) return;
    
    // Calculate magnitude of acceleration vector
    final magnitude = sqrt(
      event.x * event.x + 
      event.y * event.y + 
      event.z * event.z
    );
    
    // Vertical acceleration (assuming device is oriented normally)
    // In freefall, vertical acceleration should be close to 9.8 m/s² (gravity)
    // When exiting aircraft, there's a sudden change
    // When parachute opens, there's strong deceleration
    
    final verticalAccel = event.z.abs(); // Adjust based on device orientation
    
    final reading = SensorReading(
      timestamp: DateTime.now(),
      acceleration: magnitude,
      verticalAcceleration: verticalAccel,
      velocity: _calculateVelocity(),
    );
    
    _readings.add(reading);
    
    // Keep only last 5 seconds of readings (at 10 Hz = 50 readings)
    if (_readings.length > 50) {
      _readings.removeAt(0);
    }
    
    _processReading(reading);
  }
  
  void _onGyroscopeEvent(GyroscopeEvent event) {
    // Can be used for orientation detection
    // For now, we'll focus on accelerometer data
  }
  
  void _processReading(SensorReading reading) {
    if (!_inFreefall && _exitTime == null) {
      // Detect exit: sudden acceleration change or drop
      if (_detectExit(reading)) {
        _exitTime = reading.timestamp;
        _inFreefall = true;
        print('Exit detected at ${_exitTime}');
      }
    } else if (_inFreefall && _deploymentTime == null) {
      // Detect deployment: strong deceleration
      if (_detectDeployment(reading)) {
        _deploymentTime = reading.timestamp;
        _inFreefall = false;
        print('Deployment detected at ${_deploymentTime}');
        _calculateFinalStats();
      } else {
        // Update max velocity during freefall
        final velocity = reading.velocity;
        if (velocity > _maxVerticalVelocity) {
          _maxVerticalVelocity = velocity;
        }
        _updateCurrentStats();
      }
    }
  }
  
  bool _detectExit(SensorReading reading) {
    if (_readings.length < 5) return false;
    
    // Check for sudden change in acceleration (exit from aircraft)
    final recentReadings = _readings.sublist(_readings.length - 5);
    final avgAccel = recentReadings.map((r) => r.acceleration).reduce((a, b) => a + b) / recentReadings.length;
    
    // Exit is detected when acceleration changes significantly
    // (e.g., from aircraft movement to freefall)
    final accelChange = (reading.acceleration - avgAccel).abs();
    
    return accelChange > exitAccelerationThreshold;
  }
  
  bool _detectDeployment(SensorReading reading) {
    if (_readings.length < 3) return false;
    
    // Check for strong deceleration (parachute opening)
    final recentReadings = _readings.sublist(_readings.length - 3);
    final avgAccel = recentReadings.map((r) => r.acceleration).reduce((a, b) => a + b) / recentReadings.length;
    
    // Deployment is detected when there's strong deceleration
    // (acceleration significantly higher than freefall)
    return reading.acceleration > deploymentDecelerationThreshold;
  }
  
  double _calculateVelocity() {
    if (_readings.length < 2) return 0.0;
    if (_exitTime == null) return 0.0;
    
    // Simple velocity calculation based on acceleration over time
    // v = v0 + a*t
    // For more accuracy, integrate acceleration over time
    
    double velocity = 0.0;
    for (int i = 1; i < _readings.length; i++) {
      final prev = _readings[i - 1];
      final curr = _readings[i];
      final dt = curr.timestamp.difference(prev.timestamp).inMilliseconds / 1000.0;
      
      // Assuming freefall acceleration ~9.8 m/s²
      // Subtract gravity to get net acceleration
      final netAccel = curr.verticalAcceleration - 9.8;
      velocity += netAccel * dt;
      
      // Terminal velocity for skydiver is ~55 m/s
      if (velocity > 55.0) velocity = 55.0;
    }
    
    return velocity.abs();
  }
  
  void _updateCurrentStats() {
    if (_exitTime == null) return;
    
    final now = DateTime.now();
    final duration = now.difference(_exitTime!).inMilliseconds / 1000.0;
    
    _currentStats = FreefallStats(
      freefallDurationSeconds: duration,
      maxVerticalVelocityMs: _maxVerticalVelocity,
      exitTime: _exitTime,
      deploymentTime: _deploymentTime,
    );
    
    _statsController.add(_currentStats);
  }
  
  void _calculateFinalStats() {
    if (_exitTime == null) return;
    
    final endTime = _deploymentTime ?? DateTime.now();
    final duration = endTime.difference(_exitTime!).inMilliseconds / 1000.0;
    
    // Validate duration
    if (duration < minFreefallDuration || duration > maxFreefallDuration) {
      _currentStats = null;
      _statsController.add(null);
      return;
    }
    
    _currentStats = FreefallStats(
      freefallDurationSeconds: duration,
      maxVerticalVelocityMs: _maxVerticalVelocity,
      exitTime: _exitTime,
      deploymentTime: _deploymentTime,
    );
    
    _statsController.add(_currentStats);
  }
  
  // Simulated detection for testing
  void _startSimulatedDetection() {
    Timer.periodic(sensorUpdateInterval, (timer) {
      if (!_isDetecting) {
        timer.cancel();
        return;
      }
      
      final now = DateTime.now();
      final elapsed = _readings.isEmpty 
          ? 0.0 
          : now.difference(_readings.first.timestamp).inMilliseconds / 1000.0;
      
      // Simulate realistic freefall data
      double acceleration;
      double velocity;
      
      if (elapsed < 2.0) {
        // Phase 1: Exit from aircraft (first 2 seconds)
        acceleration = 12.0 + Random().nextDouble() * 3.0; // High acceleration
        velocity = elapsed * 10.0; // Accelerating
      } else if (elapsed < 50.0) {
        // Phase 2: Freefall (2-50 seconds)
        acceleration = 9.8 + (Random().nextDouble() - 0.5) * 0.5; // Near gravity
        velocity = 9.8 * (elapsed - 2.0); // Terminal velocity ~55 m/s
        if (velocity > 55.0) velocity = 55.0;
      } else {
        // Phase 3: Deployment (after 50 seconds)
        acceleration = 25.0 + Random().nextDouble() * 10.0; // Strong deceleration
        velocity = 55.0 - (elapsed - 50.0) * 5.0; // Decelerating
        if (velocity < 0) velocity = 0;
      }
      
      final reading = SensorReading(
        timestamp: now,
        acceleration: acceleration,
        verticalAcceleration: acceleration,
        velocity: velocity,
      );
      
      _readings.add(reading);
      
      // Keep only last 5 seconds
      if (_readings.length > 50) {
        _readings.removeAt(0);
      }
      
      // Auto-detect exit at start
      if (_exitTime == null && elapsed > 0.5) {
        _exitTime = now.subtract(Duration(milliseconds: (elapsed * 1000).round()));
        _inFreefall = true;
        print('Simulated exit detected');
      }
      
      // Auto-detect deployment after 50 seconds
      if (_inFreefall && _deploymentTime == null && elapsed > 50.0) {
        _deploymentTime = now;
        _inFreefall = false;
        print('Simulated deployment detected');
        _calculateFinalStats();
        timer.cancel();
      }
      
      // Update max velocity
      if (velocity > _maxVerticalVelocity) {
        _maxVerticalVelocity = velocity;
      }
      
      _updateCurrentStats();
    });
  }
  
  void dispose() {
    _statsController.close();
    stopDetection();
  }
}

class SensorReading {
  final DateTime timestamp;
  final double acceleration;
  final double verticalAcceleration;
  final double velocity;
  
  SensorReading({
    required this.timestamp,
    required this.acceleration,
    required this.verticalAcceleration,
    required this.velocity,
  });
}
