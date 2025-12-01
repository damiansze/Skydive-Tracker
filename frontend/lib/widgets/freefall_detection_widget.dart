import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/freefall_stats.dart';
import '../services/freefall_detection_service.dart';
import 'package:intl/intl.dart';

class FreefallDetectionWidget extends ConsumerStatefulWidget {
  final Function(FreefallStats?) onStatsUpdated;

  const FreefallDetectionWidget({
    super.key,
    required this.onStatsUpdated,
  });

  @override
  ConsumerState<FreefallDetectionWidget> createState() => _FreefallDetectionWidgetState();
}

class _FreefallDetectionWidgetState extends ConsumerState<FreefallDetectionWidget> {
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
          // Only update _currentStats if stats is not null (exit detected)
          // If stats is null, detection is running but exit not yet detected
          if (stats != null) {
            _currentStats = stats;
          }
        });
        widget.onStatsUpdated(stats);
      }
    });

    // Update UI every second to show detection runtime
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isDetecting) {
        setState(() {}); // Trigger rebuild to update runtime display
      } else {
        timer.cancel();
      }
    });

    try {
      await _detectionService!.startDetection();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDetecting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Starten der Detektion: $e')),
        );
      }
    }
  }

  Future<void> _stopDetection() async {
    if (_detectionService == null) return;
    
    try {
      await _detectionService!.stopDetection();
      _statsSubscription?.cancel();
      _updateTimer?.cancel();
      
      final finalStats = _detectionService!.getCurrentStats();
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
          SnackBar(content: Text('Fehler beim Stoppen der Detektion: $e')),
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flight_takeoff,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Freefall-Detektion',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (FreefallDetectionService.useSimulatedSensors)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'SIMULATION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
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
        Text(
          'Starte die Freefall-Detektion, um automatisch Exit, Deployment und Geschwindigkeit zu erfassen.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _startDetection,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Detektion starten'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
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
        // Status indicator
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hasExit 
                ? (hasDeployment ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1))
                : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: hasExit 
                      ? (hasDeployment ? Colors.green : Colors.red)
                      : Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasExit 
                          ? (hasDeployment ? 'Deployment erkannt' : 'Freefall aktiv')
                          : 'Warte auf Exit...',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: hasExit 
                            ? (hasDeployment ? Colors.green : Colors.red)
                            : Colors.orange,
                      ),
                    ),
                    if (!hasExit) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Die Detektion läuft und erkennt automatisch den Exit',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Laufzeit: ${_getDetectionRuntime()}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Live stats - nur anzeigen wenn Exit erkannt wurde
        if (hasExit) ...[
          _buildStatRow(
            'Freefall-Dauer',
            _currentStats!.freefallDurationSeconds != null
                ? '${_currentStats!.freefallDurationSeconds!.toStringAsFixed(1)} s'
                : '-',
            Icons.timer,
          ),
          const SizedBox(height: 8),
          _buildStatRow(
            'Max. Geschwindigkeit',
            _currentStats!.maxVerticalVelocityMs != null
                ? '${_currentStats!.maxVerticalVelocityKmh!.toStringAsFixed(1)} km/h'
                : '-',
            Icons.speed,
          ),
          const SizedBox(height: 8),
          _buildStatRow(
            'Exit-Zeit',
            DateFormat('HH:mm:ss').format(_currentStats!.exitTime!),
            Icons.flight_takeoff,
          ),
          if (hasDeployment) ...[
            const SizedBox(height: 8),
            _buildStatRow(
              'Deployment-Zeit',
              DateFormat('HH:mm:ss').format(_currentStats!.deploymentTime!),
              Icons.paragliding,
            ),
          ],
          const SizedBox(height: 16),
        ] else ...[
          // Info während Wartezeit
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Die Detektion läuft. Der Exit wird automatisch erkannt, sobald du springst. Die Freefall-Dauer wird erst ab dem Exit berechnet.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Control buttons
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isDetecting ? _stopDetection : null,
            icon: const Icon(Icons.stop),
            label: const Text('Detektion stoppen'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Detektion abgeschlossen',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Final stats
        if (_currentStats != null) ...[
          _buildStatRow(
            'Freefall-Dauer',
            _currentStats!.freefallDurationSeconds != null
                ? '${_currentStats!.freefallDurationSeconds!.toStringAsFixed(1)} s'
                : '-',
            Icons.timer,
          ),
          const SizedBox(height: 8),
          _buildStatRow(
            'Max. Geschwindigkeit',
            _currentStats!.maxVerticalVelocityMs != null
                ? '${_currentStats!.maxVerticalVelocityKmh!.toStringAsFixed(1)} km/h'
                : '-',
            Icons.speed,
          ),
          const SizedBox(height: 8),
          if (_currentStats!.exitTime != null)
            _buildStatRow(
              'Exit-Zeit',
              DateFormat('HH:mm:ss').format(_currentStats!.exitTime!),
              Icons.flight_takeoff,
            ),
          if (_currentStats!.deploymentTime != null) ...[
            const SizedBox(height: 8),
            _buildStatRow(
              'Deployment-Zeit',
              DateFormat('HH:mm:ss').format(_currentStats!.deploymentTime!),
              Icons.paragliding,
            ),
          ],
          const SizedBox(height: 16),
        ],
        
        // Control buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _resetDetection,
                icon: const Icon(Icons.refresh),
                label: const Text('Zurücksetzen'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: _startDetection,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Erneut starten'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
