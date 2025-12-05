import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/jump.dart';
import '../../models/freefall_stats.dart';
import '../../models/weather.dart';
import '../../providers/jump_provider.dart';
import '../../services/geocoding_service.dart';
import '../../services/weather_service.dart';
import '../../widgets/wear_os/wear_scaffold.dart';
import '../../widgets/wear_os/wear_time_picker.dart';
import '../../widgets/wear_os/wear_date_picker.dart';
import '../../widgets/wear_os/wear_freefall_widget.dart';
import '../settings_screen.dart';

/// Simplified jump recording screen for WearOS
class WearAddJumpScreen extends ConsumerStatefulWidget {
  const WearAddJumpScreen({super.key});

  @override
  ConsumerState<WearAddJumpScreen> createState() => _WearAddJumpScreenState();
}

class _WearAddJumpScreenState extends ConsumerState<WearAddJumpScreen> {
  // Jump data
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _location = '';
  double? _latitude;
  double? _longitude;
  int _altitude = 4000; // Default altitude in meters
  JumpType _jumpType = JumpType.SOLO;
  WeatherData? _weather;
  
  bool _isLoading = false;
  bool _isSaving = false;
  FreefallStats? _freefallStats;
  
  // Text controller for location input
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }
  
  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    // On WearOS, Geolocator causes native crashes because FusedLocationClient
    // methods like isLocationServiceEnabled are not supported.
    // For WearOS, we skip automatic location detection and let user enter manually.
    // The location can also be synced from the phone app later.
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _location = ''; // User will enter manually
      });
    }
  }
  
  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    
    try {
      final result = await GeocodingService.getCoordinatesFromAddress(query);
      if (result != null && mounted) {
        setState(() {
          _latitude = result.latitude;
          _longitude = result.longitude;
          _location = query;
        });
        _fetchWeather();
      }
    } catch (e) {
      debugPrint('Error searching location: $e');
    }
  }
  
  void _showLocationDialog() {
    _locationController.text = _location;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(8),
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        titlePadding: const EdgeInsets.only(top: 8, left: 8, right: 8),
        title: const Text('Ort eingeben', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _locationController,
          autofocus: true,
          style: const TextStyle(fontSize: 10),
          decoration: const InputDecoration(
            hintText: 'z.B. Interlaken, CH',
            hintStyle: TextStyle(fontSize: 9),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            if (value.isNotEmpty) {
              setState(() => _location = value);
              _searchLocation(value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Abbruch', style: TextStyle(fontSize: 9)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final value = _locationController.text;
              if (value.isNotEmpty) {
                setState(() => _location = value);
                _searchLocation(value);
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('OK', style: TextStyle(fontSize: 9)),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchWeather() async {
    if (_latitude == null || _longitude == null) return;
    
    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final weather = await WeatherService.getWeather(
      latitude: _latitude!,
      longitude: _longitude!,
      dateTime: dateTime,
    );

    if (mounted) {
      setState(() => _weather = weather);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await WearDatePicker.show(
      context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _fetchWeather();
    }
  }

  Future<void> _selectTime() async {
    final timeFormat = ref.read(timeFormatProvider);
    final TimeOfDay? picked = await WearTimePicker.show(
      context,
      initialTime: _selectedTime,
      use24HourFormat: timeFormat == '24h',
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
      _fetchWeather();
    }
  }
  
  String _formatTime(TimeOfDay time) {
    final timeFormat = ref.read(timeFormatProvider);
    if (timeFormat == '24h') {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return time.format(context);
    }
  }

  void _adjustAltitude(int delta) {
    setState(() {
      _altitude = (_altitude + delta).clamp(500, 15000);
    });
  }

  void _showWearSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 10),
          textAlign: TextAlign.center,
        ),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveJump() async {
    if (_location.isEmpty) {
      _showWearSnackBar('Ort erforderlich', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await ref.read(jumpNotifierProvider.notifier).createJump(
        date: dateTime,
        location: _location,
        latitude: _latitude,
        longitude: _longitude,
        altitude: _altitude,
        jumpType: _jumpType,
        freefallStats: _freefallStats,
        weather: _weather,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        _showWearSnackBar('Sprung gespeichert!');
      }
    } catch (e) {
      if (mounted) {
        _showWearSnackBar('Fehler: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WearScaffold(
      title: 'Neuer Sprung',
      showBackButton: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : PageView(
              children: [
                _buildStep1DateLocation(),
                _buildStep2Details(),
                _buildStep3Summary(),
              ],
            ),
    );
  }

  // Step 1: Date, Time, Location
  Widget _buildStep1DateLocation() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          // Date
          WearCard(
            onTap: _selectDate,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 14),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Datum', style: TextStyle(fontSize: 8)),
                    Text(
                      DateFormat('dd.MM.yyyy').format(_selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          
          // Time
          WearCard(
            onTap: _selectTime,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 14),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Zeit', style: TextStyle(fontSize: 8)),
                    Text(
                      _formatTime(_selectedTime),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          
          // Location - tappable to enter manually
          WearCard(
            onTap: _showLocationDialog,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.red),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ort (tippen)', style: TextStyle(fontSize: 8)),
                      Text(
                        _location.isEmpty ? 'Tippen zum Eingeben' : _location,
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 9,
                          color: _location.isEmpty ? Colors.grey : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.edit, size: 12, color: Colors.grey),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          const Text('Wische →', style: TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  // Step 2: Altitude, Type, and Freefall Detection
  Widget _buildStep2Details() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          // Altitude with +/- buttons - compact
          WearCard(
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                const Text('Höhe', style: TextStyle(fontSize: 9)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle, size: 22),
                      onPressed: () => _adjustAltitude(-100),
                      color: Colors.red,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                    Text(
                      '$_altitude m',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, size: 22),
                      onPressed: () => _adjustAltitude(100),
                      color: Colors.green,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          
          // Jump Type - compact
          WearCard(
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                const Text('Sprungtyp', style: TextStyle(fontSize: 9)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 2,
                  runSpacing: 2,
                  alignment: WrapAlignment.center,
                  children: JumpType.values.take(4).map((type) {
                    final isSelected = _jumpType == type;
                    return GestureDetector(
                      onTap: () => setState(() => _jumpType = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          type.displayName,
                          style: TextStyle(
                            fontSize: 8,
                            color: isSelected ? Colors.white : null,
                            fontWeight: isSelected ? FontWeight.bold : null,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          
          // Freefall Detection
          WearFreefallWidget(
            onStatsUpdated: (stats) {
              setState(() => _freefallStats = stats);
            },
          ),
          
          const SizedBox(height: 4),
          const Text('← | →', style: TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  // Step 3: Summary and Save
  Widget _buildStep3Summary() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          // Summary Card - compact
          WearCard(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.paragliding, size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    const Text('Übersicht', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                  ],
                ),
                const Divider(height: 8),
                _buildSummaryRow(Icons.calendar_today, DateFormat('dd.MM.yy HH:mm').format(
                  DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    _selectedTime.hour,
                    _selectedTime.minute,
                  ),
                )),
                _buildSummaryRow(Icons.location_on, _location.isEmpty ? '-' : _location),
                _buildSummaryRow(Icons.height, '$_altitude m'),
                _buildSummaryRow(Icons.flight_takeoff, _jumpType.displayName),
                if (_freefallStats != null) ...[
                  const Divider(height: 6),
                  _buildSummaryRow(
                    Icons.timer,
                    'Freefall: ${_freefallStats!.freefallDurationSeconds?.toStringAsFixed(1) ?? '-'} s',
                  ),
                  if (_freefallStats!.maxVerticalVelocityKmh != null)
                    _buildSummaryRow(
                      Icons.speed,
                      'Max: ${_freefallStats!.maxVerticalVelocityKmh!.toStringAsFixed(0)} km/h',
                    ),
                ],
                if (_weather != null && _weather!.hasData) ...[
                  const Divider(height: 6),
                  _buildSummaryRow(
                    Icons.thermostat,
                    '${_weather!.temperatureCelsius?.toStringAsFixed(0) ?? '-'}°C',
                  ),
                  if (_weather!.windSpeedKmh != null)
                    _buildSummaryRow(
                      Icons.air,
                      '${_weather!.windSpeedKmh!.toStringAsFixed(0)} km/h',
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          
          // Save Button - compact
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveJump,
              icon: _isSaving 
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save, size: 14),
              label: Text(_isSaving ? '...' : 'Speichern', style: const TextStyle(fontSize: 10)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Icon(icon, size: 10, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 9),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

