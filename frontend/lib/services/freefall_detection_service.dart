import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/freefall_stats.dart';

/// Service for detecting freefall using device sensors
class FreefallDetectionService {
  // For testing: Use environment variable or runtime flag to enable simulation
  // Set USE_SIMULATED_SENSORS=true when running: flutter run --dart-define=USE_SIMULATED_SENSORS=true
  // Or use setUseSimulation() to toggle at runtime
  static bool _useSimulationOverride = false;
  static bool get useSimulatedSensors => 
      bool.fromEnvironment('USE_SIMULATED_SENSORS', defaultValue: false) || _useSimulationOverride;
  
  /// Set simulation mode at runtime (for testing/debugging)
  static void setUseSimulation(bool enabled) {
    _useSimulationOverride = enabled;
  }
  
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
  Timer? _simulationTimer;
  
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
    // Don't do anything if already stopped
    if (!_isDetecting) {
      return;
    }
    
    _isDetecting = false;

    // Stop simulation timer
    _simulationTimer?.cancel();
    _simulationTimer = null;

    // Stop sensor subscriptions
    await _accelerometerSubscription?.cancel();
    await _gyroscopeSubscription?.cancel();
    await _magnetometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _magnetometerSubscription = null;

    // Calculate final stats if we have exit time and haven't already calculated them
    if (_exitTime != null && _deploymentTime == null) {
      // If deployment wasn't detected, use current time as end time
      _deploymentTime = DateTime.now();
      _calculateFinalStats();
    } else if (_exitTime != null && _currentStats == null) {
      // If we have exit time but no stats yet, calculate them
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
    // (acceleration significantly higher than freefall average)
    // Compare current reading to average to detect sudden change
    return reading.acceleration > deploymentDecelerationThreshold && 
           reading.acceleration > avgAccel * 2.0; // Must be at least 2x the average
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
    
    // Only add to stream if it's not closed
    if (!_statsController.isClosed) {
      _statsController.add(_currentStats);
    }
  }
  
  void _calculateFinalStats() {
    if (_exitTime == null) return;
    
    final endTime = _deploymentTime ?? DateTime.now();
    final duration = endTime.difference(_exitTime!).inMilliseconds / 1000.0;
    
    // Validate duration
    if (duration < minFreefallDuration || duration > maxFreefallDuration) {
      _currentStats = null;
      // Only add to stream if it's not closed
      if (!_statsController.isClosed) {
        _statsController.add(null);
      }
      return;
    }
    
    _currentStats = FreefallStats(
      freefallDurationSeconds: duration,
      maxVerticalVelocityMs: _maxVerticalVelocity,
      exitTime: _exitTime,
      deploymentTime: _deploymentTime,
    );
    
    // Only add to stream if it's not closed
    if (!_statsController.isClosed) {
      _statsController.add(_currentStats);
    }
  }
  
  // Simulated detection for testing
  void _startSimulatedDetection() {
    _simulationTimer?.cancel(); // Cancel any existing timer
    _simulationTimer = Timer.periodic(sensorUpdateInterval, (timer) {
      if (!_isDetecting) {
        timer.cancel();
        _simulationTimer = null;
        return;
      }
      
      final now = DateTime.now();
      final elapsed = _readings.isEmpty 
          ? 0.0 
          : now.difference(_readings.first.timestamp).inMilliseconds / 1000.0;
      
      // Simulate realistic freefall data
      double acceleration;
      double velocity;
      
      // Calculate time since exit (if exit detected)
      final timeSinceExit = _exitTime != null 
          ? now.difference(_exitTime!).inMilliseconds / 1000.0
          : 0.0;
      
      if (elapsed < 2.0) {
        // Phase 1: Waiting in aircraft (first 2 seconds) - normal flight
        acceleration = 9.8 + (Random().nextDouble() - 0.5) * 0.3; // Near gravity (in aircraft)
        velocity = 0.0; // No freefall velocity yet
      } else if (timeSinceExit < 48.0) {
        // Phase 2: Freefall (after exit, up to 48 seconds)
        // Terminal velocity for skydiver: ~55 m/s = ~198 km/h
        final freefallTime = timeSinceExit;
        // Accelerate to terminal velocity over ~10 seconds
        if (freefallTime < 10.0) {
          velocity = 9.8 * freefallTime; // Accelerating
          if (velocity > 55.0) velocity = 55.0;
        } else {
          velocity = 55.0 + (Random().nextDouble() - 0.5) * 2.0; // Terminal velocity with small variations
          if (velocity > 60.0) velocity = 60.0; // Max realistic speed
          if (velocity < 50.0) velocity = 50.0;
        }
        acceleration = 9.8 + (Random().nextDouble() - 0.5) * 0.5; // Near gravity
      } else {
        // Phase 3: Deployment (after 48 seconds of freefall = 50 seconds total)
        acceleration = 30.0 + Random().nextDouble() * 10.0; // Strong deceleration
        final deploymentTime = timeSinceExit - 48.0;
        velocity = 55.0 - deploymentTime * 8.0; // Rapid deceleration
        if (velocity < 5.0) velocity = 5.0; // Minimum speed under canopy
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
      
      // Auto-detect exit after 2 seconds (simulating waiting in aircraft, then exit)
      if (_exitTime == null && elapsed >= 2.0) {
        _exitTime = now;
        _inFreefall = true;
        print('Simulated exit detected at ${elapsed}s');
      }
      
      // Auto-detect deployment after 48 seconds of freefall (use timeSinceExit, not elapsed)
      if (_inFreefall && _deploymentTime == null && timeSinceExit >= 48.0) {
        _deploymentTime = now;
        _inFreefall = false;
        print('Simulated deployment detected at ${elapsed}s (${timeSinceExit.toStringAsFixed(1)}s freefall)');
        _isDetecting = false; // Stop detection first
        _calculateFinalStats(); // Calculate final stats (will check if stream is closed)
        timer.cancel();
        _simulationTimer = null;
        return;
      }
      
      // Update max velocity during freefall (only count freefall phase, use actual velocity from simulation)
      if (_inFreefall && timeSinceExit > 0) {
        // Use the simulated velocity directly
        if (velocity > _maxVerticalVelocity) {
          _maxVerticalVelocity = velocity;
        }
      }
      
      // Send updates
      if (_exitTime != null) {
        _updateCurrentStats();
      } else {
        // Send null stats to indicate detection is running but no exit yet
        if (!_statsController.isClosed) {
          _statsController.add(null);
        }
      }
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
