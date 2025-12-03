import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/freefall_stats.dart';
import '../../services/freefall_detection_service.dart';

/// Compact freefall detection widget for WearOS
class WearFreefallWidget extends StatefulWidget {
  final Function(FreefallStats?) onStatsUpdated;

  const WearFreefallWidget({
    super.key,
    required this.onStatsUpdated,
  });

  @override
  State<WearFreefallWidget> createState() => _WearFreefallWidgetState();
}

class _WearFreefallWidgetState extends State<WearFreefallWidget> {
  FreefallDetectionService? _detectionService;
  FreefallStats? _currentStats;
  bool _isDetecting = false;
  StreamSubscription<FreefallStats?>? _statsSubscription;
  DateTime? _detectionStartTime;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _detectionService = FreefallDetectionService();
  }

  @override
  void dispose() {
    _statsSubscription?.cancel();
    _updateTimer?.cancel();
    _detectionService?.dispose();
    super.dispose();
  }

  Future<void> _startDetection() async {
    if (_detectionService == null) {
      _detectionService = FreefallDetectionService();
    }

    setState(() {
      _isDetecting = true;
      _detectionStartTime = DateTime.now();
    });

    _statsSubscription = _detectionService!.statsStream.listen((stats) {
      if (mounted) {
        setState(() {
          if (stats != null) {
            _currentStats = stats;
          }
        });
        widget.onStatsUpdated(stats);
      }
    }, onError: (error) {
      debugPrint('Error in stats stream: $error');
    });

    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isDetecting) {
        setState(() {});
      } else {
        timer.cancel();
      }
    });

    try {
      await _detectionService!.startDetection();
    } catch (e) {
      if (mounted) {
        setState(() => _isDetecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e', style: const TextStyle(fontSize: 10))),
        );
      }
    }
  }

  Future<void> _stopDetection() async {
    if (_detectionService == null) return;

    try {
      final statsBeforeStop = _detectionService!.getCurrentStats();
      await _detectionService!.stopDetection();
      _statsSubscription?.cancel();
      _updateTimer?.cancel();

      final finalStats = _detectionService!.getCurrentStats() ?? statsBeforeStop;

      if (mounted) {
        setState(() {
          _isDetecting = false;
          _currentStats = finalStats;
          _detectionStartTime = null;
        });
        widget.onStatsUpdated(finalStats);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e', style: const TextStyle(fontSize: 10))),
        );
      }
    }
  }

  void _resetDetection() {
    _detectionService?.reset();
    _updateTimer?.cancel();
    if (mounted) {
      setState(() {
        _isDetecting = false;
        _currentStats = null;
        _detectionStartTime = null;
      });
      widget.onStatsUpdated(null);
    }
  }

  String _getDetectionRuntime() {
    if (_detectionStartTime == null) return '0:00';
    final duration = DateTime.now().difference(_detectionStartTime!);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.flight_takeoff,
                  size: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'Freefall',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                if (FreefallDetectionService.useSimulatedSensors)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'SIM',
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),

            if (!_isDetecting && _currentStats == null)
              _buildIdleState()
            else if (_isDetecting)
              _buildDetectingState()
            else
              _buildCompletedState(),
          ],
        ),
      ),
    );
  }

  Widget _buildIdleState() {
    return Column(
      children: [
        const Text(
          'Drücke Start für die Freefall-Erfassung',
          style: TextStyle(fontSize: 8),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _startDetection,
            icon: const Icon(Icons.play_arrow, size: 12),
            label: const Text('Start', style: TextStyle(fontSize: 9)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 4),
              minimumSize: const Size(0, 24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetectingState() {
    final hasExit = _currentStats?.exitTime != null;
    final hasDeployment = _currentStats?.deploymentTime != null;

    return Column(
      children: [
        // Status
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: hasExit
                ? (hasDeployment ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1))
                : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: hasExit ? (hasDeployment ? Colors.green : Colors.red) : Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                hasExit
                    ? (hasDeployment ? 'Deployment' : 'Freefall')
                    : 'Warte... ${_getDetectionRuntime()}',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: hasExit ? (hasDeployment ? Colors.green : Colors.red) : Colors.orange,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Live stats
        if (hasExit) ...[
          _buildStatRow('Dauer', '${_currentStats!.freefallDurationSeconds?.toStringAsFixed(1) ?? '-'} s'),
          _buildStatRow('Speed', '${_currentStats!.maxVerticalVelocityKmh?.toStringAsFixed(0) ?? '-'} km/h'),
        ],
        const SizedBox(height: 4),

        // Stop button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _stopDetection,
            icon: const Icon(Icons.stop, size: 12),
            label: const Text('Stop', style: TextStyle(fontSize: 9)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 4),
              minimumSize: const Size(0, 24),
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedState() {
    return Column(
      children: [
        // Success indicator
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 12),
              SizedBox(width: 4),
              Text(
                'Abgeschlossen',
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Final stats
        if (_currentStats != null) ...[
          _buildStatRow('Dauer', '${_currentStats!.freefallDurationSeconds?.toStringAsFixed(1) ?? '-'} s'),
          _buildStatRow('Max', '${_currentStats!.maxVerticalVelocityKmh?.toStringAsFixed(0) ?? '-'} km/h'),
          if (_currentStats!.exitTime != null)
            _buildStatRow('Exit', DateFormat('HH:mm:ss').format(_currentStats!.exitTime!)),
        ],
        const SizedBox(height: 4),

        // Control buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _resetDetection,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  minimumSize: const Size(0, 22),
                ),
                child: const Text('Reset', style: TextStyle(fontSize: 8)),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: ElevatedButton(
                onPressed: _startDetection,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  minimumSize: const Size(0, 22),
                ),
                child: const Text('Neu', style: TextStyle(fontSize: 8)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 8)),
          Text(value, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

