import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../models/jump.dart';
import '../../models/freefall_stats.dart';
import '../../models/weather.dart';
import '../../providers/jump_provider.dart';
import '../../services/geocoding_service.dart';
import '../../services/weather_service.dart';
import '../../widgets/wear_os/wear_scaffold.dart';

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

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      _latitude = position.latitude;
      _longitude = position.longitude;
      
      // Get address
      final latLng = LatLng(_latitude!, _longitude!);
      final address = await GeocodingService.getAddressFromCoordinates(latLng);
      
      if (mounted) {
        setState(() {
          if (address != null) _location = address;
          _isLoading = false;
        });
        
        // Fetch weather
        _fetchWeather();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
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
    final DateTime? picked = await showDatePicker(
      context: context,
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
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
      _fetchWeather();
    }
  }

  void _adjustAltitude(int delta) {
    setState(() {
      _altitude = (_altitude + delta).clamp(500, 15000);
    });
  }

  Future<void> _saveJump() async {
    if (_location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ort erforderlich')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sprung gespeichert!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
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
      child: Column(
        children: [
          // Date
          WearCard(
            onTap: _selectDate,
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Datum', style: TextStyle(fontSize: 10)),
                    Text(
                      DateFormat('dd.MM.yyyy').format(_selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Time
          WearCard(
            onTap: _selectTime,
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Zeit', style: TextStyle(fontSize: 10)),
                    Text(
                      _selectedTime.format(context),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Location
          WearCard(
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 20, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ort', style: TextStyle(fontSize: 10)),
                      Text(
                        _location.isEmpty ? 'Wird ermittelt...' : _location,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          const Text('Wische nach links →', style: TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  // Step 2: Altitude and Type
  Widget _buildStep2Details() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Altitude with +/- buttons
          WearCard(
            child: Column(
              children: [
                const Text('Höhe', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle, size: 32),
                      onPressed: () => _adjustAltitude(-100),
                      color: Colors.red,
                    ),
                    Text(
                      '$_altitude m',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, size: 32),
                      onPressed: () => _adjustAltitude(100),
                      color: Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Jump Type
          WearCard(
            child: Column(
              children: [
                const Text('Sprungtyp', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: JumpType.values.take(4).map((type) {
                    final isSelected = _jumpType == type;
                    return GestureDetector(
                      onTap: () => setState(() => _jumpType = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          type.displayName,
                          style: TextStyle(
                            fontSize: 10,
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
          
          const SizedBox(height: 16),
          const Text('← Zurück | Weiter →', style: TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  // Step 3: Summary and Save
  Widget _buildStep3Summary() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Summary Card
          WearCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.paragliding, size: 24, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text('Zusammenfassung', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(),
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
                if (_weather != null && _weather!.hasData) ...[
                  const Divider(),
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
          const SizedBox(height: 12),
          
          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveJump,
              icon: _isSaving 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save, size: 18),
              label: Text(_isSaving ? 'Speichern...' : 'Speichern'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

