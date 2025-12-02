import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/jump.dart';
import '../models/equipment.dart';
import '../models/freefall_stats.dart';
import '../models/weather.dart';
import '../providers/jump_provider.dart';
import '../providers/equipment_provider.dart';
import '../services/geocoding_service.dart';
import '../services/weather_service.dart';
import '../widgets/freefall_detection_widget.dart';
import 'map_location_picker_screen.dart';
import 'settings_screen.dart';

class AddJumpScreen extends ConsumerStatefulWidget {
  final Jump? jump; // For editing existing jumps

  const AddJumpScreen({super.key, this.jump});

  @override
  ConsumerState<AddJumpScreen> createState() => _AddJumpScreenState();
}

class _AddJumpScreenState extends ConsumerState<AddJumpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _altitudeController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationFocusNode = FocusNode(); // Focus node for location field
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  double? _latitude;
  double? _longitude;
  LatLng? _currentLocation;
  JumpType? _selectedJumpType;
  JumpMethod? _selectedJumpMethod;
  
  Set<String> _selectedEquipmentIds = {};
  Map<String, bool> _checklistItems = {};
  bool _isGeocoding = false;
  List<String> _locationSuggestions = [];
  bool _showSuggestions = false;
  FreefallStats? _freefallStats;
  bool _isEditingMode = false; // For existing jumps: start in preview mode
  bool _isSelectingSuggestion = false; // Track if user is selecting a suggestion
  WeatherData? _weatherData;
  bool _isLoadingWeather = false;
  String? _weatherError;

  bool _isInitializing = true; // Track if we're still initializing
  
  @override
  void initState() {
    super.initState();
    if (widget.jump != null) {
      _loadJumpData();
      _isEditingMode = false; // Start in preview mode for existing jumps
      _isInitializing = false;
    } else {
      _isEditingMode = true; // Always editable for new jumps
      // Don't auto-fetch location on init - let user choose when to use current location
      // This prevents overwriting user input
      _isInitializing = false;
    }
    
    // Listen to location field changes for geocoding
    _locationController.addListener(_onLocationChanged);
  }

  String _formatTime(TimeOfDay time) {
    final timeFormat = ref.read(timeFormatProvider);
    if (timeFormat == '24h') {
      // 24-hour format: HH:mm
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else {
      // 12-hour format with AM/PM
      final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      return '$hour:$minute $period';
    }
  }

  void _loadJumpData() {
    final jump = widget.jump!;
    _selectedDate = jump.date;
    _selectedTime = TimeOfDay.fromDateTime(jump.date);
    _locationController.text = jump.location;
    _altitudeController.text = jump.altitude.toString();
    _notesController.text = jump.notes ?? '';
    _latitude = jump.latitude;
    _longitude = jump.longitude;
    _selectedJumpType = jump.jumpType;
    _selectedJumpMethod = jump.jumpMethod;
    _selectedEquipmentIds = jump.equipmentIds.toSet();
    _freefallStats = jump.freefallStats;
    _weatherData = jump.weather;
    
    
    if (_latitude != null && _longitude != null) {
      _currentLocation = LatLng(_latitude!, _longitude!);
    }
  }

  /// Fetch weather data for the current location and date/time
  Future<void> _fetchWeather() async {
    // Only fetch if we have coordinates
    if (_latitude == null || _longitude == null) {
      setState(() {
        _weatherError = 'Position erforderlich für Wetterdaten';
        _weatherData = null;
      });
      return;
    }

    setState(() {
      _isLoadingWeather = true;
      _weatherError = null;
    });

    try {
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
        setState(() {
          _weatherData = weather;
          _isLoadingWeather = false;
          if (weather == null) {
            _weatherError = 'Wetter konnte nicht abgerufen werden';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
          _weatherError = 'Fehler beim Abrufen der Wetterdaten';
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    // Only update location if user is not actively typing
    // This prevents overwriting user input
    if (!_isEditingMode || _locationController.text.trim().isNotEmpty) {
      // Don't overwrite if user has already entered something
      return;
    }
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _currentLocation = LatLng(_latitude!, _longitude!);
      });
      
      // Only set address if field is still empty (user hasn't typed)
      // This prevents overwriting user input
      if (mounted && _locationController.text.trim().isEmpty) {
        final address = await GeocodingService.getAddressFromCoordinates(_currentLocation!);
        // Filter out Google Maps default address
        if (address != null && 
            !address.toLowerCase().contains('amphitheatre') &&
            !address.toLowerCase().contains('mountain view')) {
          _locationController.text = address;
        }
      }
    } catch (e) {
      // Location not available
    }
  }

  Timer? _locationDebounceTimer;
  
  Future<void> _onLocationChanged() async {
    // Don't show suggestions if user is currently selecting one
    if (_isSelectingSuggestion) {
      return;
    }
    
    final locationText = _locationController.text.trim();
    
    // Cancel previous timer
    _locationDebounceTimer?.cancel();
    
    // Hide suggestions immediately if text is too short
    if (locationText.length < 3) {
      if (mounted) {
        setState(() {
          _locationSuggestions = [];
          _showSuggestions = false;
        });
      }
      return;
    }
    
    // Debounce suggestions to avoid too many API calls
    _locationDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted || _isSelectingSuggestion) return;
      
      // Check if text hasn't changed
      if (_locationController.text.trim() != locationText) return;
      
      // Get suggestions for autocomplete (only show, don't auto-select)
      try {
        final suggestions = await GeocodingService.getAddressSuggestions(locationText);
        if (mounted && !_isSelectingSuggestion && _locationController.text.trim() == locationText) {
          setState(() {
            _locationSuggestions = suggestions;
            _showSuggestions = suggestions.isNotEmpty;
          });
        }
      } catch (e) {
        // Ignore errors
      }
    });
    
    // Don't do automatic geocoding - user must explicitly select from map or suggestions
    // This prevents overwriting user input with wrong addresses
  }
  
  void _selectLocationSuggestion(String suggestion) {
    // Mark that we're selecting a suggestion to prevent onTapOutside from hiding it
    _isSelectingSuggestion = true;
    
    // Cancel any pending debounce timer to prevent suggestions from reappearing
    _locationDebounceTimer?.cancel();
    
    // Update the text field immediately
    // Remove listener temporarily to prevent _onLocationChanged from triggering
    _locationController.removeListener(_onLocationChanged);
    _locationController.text = suggestion;
    // Re-add listener after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _locationController.addListener(_onLocationChanged);
      }
    });
    
    // Hide suggestions and clear list IMMEDIATELY
    setState(() {
      _showSuggestions = false;
      _locationSuggestions = [];
    });
    
    // Unfocus the text field to dismiss keyboard
    _locationFocusNode.unfocus();
    
    // Reset the flag after a short delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _isSelectingSuggestion = false;
      }
    });
    
    // Geocode the selected suggestion
    _geocodeLocation(suggestion);
  }
  
  Future<void> _geocodeLocation(String address) async {
    if (_isGeocoding) return;
    
    setState(() {
      _isGeocoding = true;
    });
    
    try {
      final coordinates = await GeocodingService.getCoordinatesFromAddress(address);
      if (coordinates != null && mounted) {
        setState(() {
          _latitude = coordinates.latitude;
          _longitude = coordinates.longitude;
          _currentLocation = coordinates;
        });
        // Automatically fetch weather after getting coordinates
        _fetchWeather();
      }
    } catch (e) {
      // Geocoding failed, ignore
    } finally {
      if (mounted) {
        setState(() {
          _isGeocoding = false;
        });
      }
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
      setState(() {
        _selectedDate = picked;
      });
      // Refresh weather if we have coordinates
      if (_latitude != null && _longitude != null) {
        _fetchWeather();
      }
    }
  }

  Future<void> _selectTime() async {
    final timeFormat = ref.read(timeFormatProvider);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: timeFormat == '24h',
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
      // Refresh weather if we have coordinates
      if (_latitude != null && _longitude != null) {
        _fetchWeather();
      }
    }
  }

  Future<void> _openMapPicker() async {
    final LatLng? result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (context) => MapLocationPickerScreen(
          initialLocation: _currentLocation,
          currentLocation: _currentLocation,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _currentLocation = result;
      });
      
      // Get address for selected location
      // Only update if user explicitly selected a location from map
      final address = await GeocodingService.getAddressFromCoordinates(result);
      if (address != null && mounted) {
        // User explicitly selected a location, so it's safe to update
        setState(() {
          _locationController.text = address;
        });
      }
      
      // Automatically fetch weather after selecting location from map
      _fetchWeather();
    }
  }

  void _toggleEquipment(String equipmentId) {
    setState(() {
      if (_selectedEquipmentIds.contains(equipmentId)) {
        _selectedEquipmentIds.remove(equipmentId);
        _checklistItems[equipmentId] = false;
      } else {
        _selectedEquipmentIds.add(equipmentId);
        _checklistItems[equipmentId] = true;
      }
    });
  }

  Future<void> _saveJump() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    try {
      final jumpNotifier = ref.read(jumpNotifierProvider.notifier);
      
      if (widget.jump != null) {
        final updatedJump = widget.jump!.copyWith(
          date: dateTime,
          location: _locationController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          altitude: int.parse(_altitudeController.text),
          jumpType: _selectedJumpType,
          jumpMethod: _selectedJumpMethod,
          equipmentIds: _selectedEquipmentIds.toList(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          freefallStats: _freefallStats,
          weather: _weatherData,
        );
        await jumpNotifier.updateJump(updatedJump);
      } else {
        await jumpNotifier.createJump(
          date: dateTime,
          location: _locationController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          altitude: int.parse(_altitudeController.text),
          jumpType: _selectedJumpType,
          jumpMethod: _selectedJumpMethod,
          equipmentIds: _selectedEquipmentIds.toList(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          freefallStats: _freefallStats,
          weather: _weatherData,
        );
      }

      if (mounted) {
        // Statistics providers are automatically invalidated by JumpNotifier
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern: $e')),
        );
      }
    }
  }

  Widget _buildFreefallStatsDisplay(FreefallStats stats) {
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
                  'Freefall-Statistiken',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'GESPEICHERT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (stats.freefallDurationSeconds != null)
              _buildStatRow(
                'Freefall-Dauer',
                '${stats.freefallDurationSeconds!.toStringAsFixed(1)} s',
                Icons.timer,
              ),
            if (stats.freefallDurationSeconds != null && stats.maxVerticalVelocityMs != null)
              const SizedBox(height: 8),
            if (stats.maxVerticalVelocityMs != null)
              _buildStatRow(
                'Max. Geschwindigkeit',
                '${stats.maxVerticalVelocityKmh!.toStringAsFixed(1)} km/h',
                Icons.speed,
              ),
            if (stats.maxVerticalVelocityMs != null && stats.exitTime != null)
              const SizedBox(height: 8),
            if (stats.exitTime != null)
              _buildStatRow(
                'Exit-Zeit',
                DateFormat('HH:mm:ss').format(stats.exitTime!),
                Icons.flight_takeoff,
              ),
            if (stats.exitTime != null && stats.deploymentTime != null)
              const SizedBox(height: 8),
            if (stats.deploymentTime != null)
              _buildStatRow(
                'Deployment-Zeit',
                DateFormat('HH:mm:ss').format(stats.deploymentTime!),
                Icons.paragliding,
              ),
          ],
        ),
      ),
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

  Widget _buildWeatherDisplay() {
    if (_isLoadingWeather) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Wetterdaten werden geladen...'),
            ],
          ),
        ),
      );
    }

    if (_weatherError != null && _weatherData == null) {
      return Card(
        elevation: 2,
        color: Colors.orange.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _weatherError!,
                  style: TextStyle(color: Colors.orange.shade900),
                ),
              ),
              if (_latitude != null && _longitude != null && _isEditingMode)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchWeather,
                  tooltip: 'Wetter erneut abrufen',
                ),
            ],
          ),
        ),
      );
    }

    if (_weatherData == null || !_weatherData!.hasData) {
      if (_latitude == null || _longitude == null) {
        return Card(
          elevation: 2,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.cloud_off, color: Theme.of(context).colorScheme.outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Wähle eine Position auf der Karte, um Wetterdaten abzurufen',
                    style: TextStyle(color: Theme.of(context).colorScheme.outline),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    final weather = _weatherData!;
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
                  _getWeatherIcon(weather.weatherCode),
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Wetterbedingungen',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (_isEditingMode)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _fetchWeather,
                    tooltip: 'Wetter aktualisieren',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            if (weather.weatherDescription != null) ...[
              const SizedBox(height: 8),
              Text(
                weather.weatherDescription!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            // Temperature
            if (weather.temperatureCelsius != null)
              _buildWeatherRow(
                'Temperatur',
                '${weather.temperatureCelsius!.toStringAsFixed(1)}°C',
                Icons.thermostat,
              ),
            if (weather.temperatureCelsius != null && weather.hasWindData)
              const SizedBox(height: 8),
            // Wind
            if (weather.hasWindData)
              _buildWeatherRow(
                'Wind',
                _formatWindInfo(weather),
                Icons.air,
              ),
            if (weather.windGustsKmh != null) ...[
              const SizedBox(height: 8),
              _buildWeatherRow(
                'Böen',
                '${weather.windGustsKmh!.toStringAsFixed(1)} km/h',
                Icons.air,
              ),
            ],
            if (weather.cloudCoverPercent != null) ...[
              const SizedBox(height: 8),
              _buildWeatherRow(
                'Bewölkung',
                '${weather.cloudCoverPercent}%',
                Icons.cloud,
              ),
            ],
            if (weather.humidityPercent != null) ...[
              const SizedBox(height: 8),
              _buildWeatherRow(
                'Luftfeuchtigkeit',
                '${weather.humidityPercent}%',
                Icons.water_drop,
              ),
            ],
            if (weather.visibilityKm != null) ...[
              const SizedBox(height: 8),
              _buildWeatherRow(
                'Sichtweite',
                '${weather.visibilityKm!.toStringAsFixed(1)} km',
                Icons.visibility,
              ),
            ],
            if (weather.pressureHpa != null) ...[
              const SizedBox(height: 8),
              _buildWeatherRow(
                'Luftdruck',
                '${weather.pressureHpa!.toStringAsFixed(0)} hPa',
                Icons.speed,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherRow(String label, String value, IconData icon) {
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

  String _formatWindInfo(WeatherData weather) {
    final parts = <String>[];
    if (weather.windSpeedKmh != null) {
      parts.add('${weather.windSpeedKmh!.toStringAsFixed(1)} km/h');
    }
    if (weather.windDirectionName != null) {
      parts.add('aus ${weather.windDirectionName}');
    }
    return parts.join(' ');
  }

  IconData _getWeatherIcon(int? code) {
    if (code == null) return Icons.cloud;
    
    if (code == 0) return Icons.wb_sunny;
    if (code <= 3) return Icons.cloud;
    if (code <= 48) return Icons.foggy;
    if (code <= 67) return Icons.grain; // rain/drizzle
    if (code <= 77) return Icons.ac_unit; // snow
    if (code <= 82) return Icons.shower;
    if (code <= 86) return Icons.ac_unit;
    if (code >= 95) return Icons.thunderstorm;
    
    return Icons.cloud;
  }

  @override
  void dispose() {
    _locationDebounceTimer?.cancel();
    _locationController.removeListener(_onLocationChanged);
    _locationController.dispose();
    _altitudeController.dispose();
    _notesController.dispose();
    _locationFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final equipmentAsync = ref.watch(equipmentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.jump != null 
            ? (_isEditingMode ? 'Sprung bearbeiten' : 'Sprung-Details')
            : 'Neuer Sprung'),
        actions: widget.jump != null && !_isEditingMode
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Editieren',
                  onPressed: () {
                    setState(() {
                      _isEditingMode = true;
                    });
                  },
                ),
              ]
            : null,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Date/Time Selection
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Datum'),
                  subtitle: Text(DateFormat('dd.MM.yyyy').format(_selectedDate)),
                  trailing: _isEditingMode ? const Icon(Icons.chevron_right) : null,
                  onTap: _isEditingMode ? _selectDate : null,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Uhrzeit'),
                  subtitle: Text(_formatTime(_selectedTime)),
                  trailing: _isEditingMode ? const Icon(Icons.chevron_right) : null,
                  onTap: _isEditingMode ? _selectTime : null,
                ),
              ),
              const SizedBox(height: 16),
              
              // Location with Autocomplete
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _locationController,
                    focusNode: _locationFocusNode,
                    readOnly: !_isEditingMode,
                    decoration: InputDecoration(
                      labelText: 'Ort *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.location_on),
                      suffixIcon: _isGeocoding && _isEditingMode
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    validator: _isEditingMode ? (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Bitte geben Sie einen Ort ein';
                      }
                      return null;
                    } : null,
                    onTap: _isEditingMode ? () {
                      setState(() {
                        if (_locationController.text.length >= 3) {
                          _showSuggestions = _locationSuggestions.isNotEmpty;
                        }
                      });
                    } : null,
                    onChanged: _isEditingMode ? (value) {
                      _onLocationChanged();
                    } : null,
                    onTapOutside: _isEditingMode ? (event) {
                      // Only hide suggestions if user is not selecting a suggestion
                      // Use a small delay to allow tap events on suggestions to process first
                      if (!_isSelectingSuggestion) {
                        Future.delayed(const Duration(milliseconds: 50), () {
                          if (mounted && !_isSelectingSuggestion) {
                            setState(() {
                              _showSuggestions = false;
                            });
                          }
                        });
                      }
                    } : null,
                  ),
                  if (_showSuggestions && _locationSuggestions.isNotEmpty && _isEditingMode)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _locationSuggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _locationSuggestions[index];
                          return InkWell(
                            onTap: () {
                              _selectLocationSuggestion(suggestion);
                            },
                            child: ListTile(
                              dense: true,
                              leading: const Icon(Icons.location_on, size: 20),
                              title: Text(
                                suggestion,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Map Selection Button
              Card(
                child: InkWell(
                  onTap: _isEditingMode ? _openMapPicker : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.map, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Position auf Karte auswählen',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (_latitude != null && _longitude != null)
                                Text(
                                  '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                )
                              else
                                Text(
                                  'Keine Position ausgewählt',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_isEditingMode) const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Weather Display
              _buildWeatherDisplay(),
              const SizedBox(height: 16),
              
              // Jump Type
              DropdownButtonFormField<JumpType>(
                value: _selectedJumpType,
                decoration: const InputDecoration(
                  labelText: 'Sprungtyp',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flight_takeoff),
                ),
                items: JumpType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: _isEditingMode ? (value) {
                  setState(() {
                    _selectedJumpType = value;
                  });
                } : null,
              ),
              const SizedBox(height: 16),
              
              // Jump Method
              DropdownButtonFormField<JumpMethod>(
                value: _selectedJumpMethod,
                decoration: const InputDecoration(
                  labelText: 'Sprungmethode',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.airplanemode_active),
                ),
                items: JumpMethod.values.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(method.displayName),
                  );
                }).toList(),
                onChanged: _isEditingMode ? (value) {
                  setState(() {
                    _selectedJumpMethod = value;
                  });
                } : null,
              ),
              const SizedBox(height: 16),
              
              // Altitude
              TextFormField(
                controller: _altitudeController,
                readOnly: !_isEditingMode,
                decoration: const InputDecoration(
                  labelText: 'Höhe (m) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.height),
                ),
                keyboardType: TextInputType.number,
                validator: _isEditingMode ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte geben Sie eine Höhe ein';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Bitte geben Sie eine gültige Höhe ein';
                  }
                  return null;
                } : null,
              ),
              const SizedBox(height: 16),
              
              // Equipment Übersicht
              equipmentAsync.when(
                data: (equipment) {
                  // Combine date and time for jump date
                  final jumpDateTime = DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    _selectedTime.hour,
                    _selectedTime.minute,
                  );
                  
                  // Filter equipment available at jump date
                  // Equipment is available if:
                  // 1. It was purchased before or on jump date (or has no purchase date)
                  // 2. It was not deactivated before or on jump date (or has no deactivation date)
                  // 3. Include equipment that was already selected for this jump (for editing)
                  final availableEquipment = equipment.where((eq) {
                    // Check if equipment was purchased before or on jump date
                    final wasPurchased = eq.purchaseDate == null || 
                                       eq.purchaseDate!.isBefore(jumpDateTime) || 
                                       eq.purchaseDate!.isAtSameMomentAs(jumpDateTime);
                    
                    // Check if equipment was not deactivated before or on jump date
                    final wasNotDeactivated = eq.deactivationDate == null || 
                                             eq.deactivationDate!.isAfter(jumpDateTime);
                    
                    // Include if available at jump date OR if already selected for this jump
                    return (wasPurchased && wasNotDeactivated) || _selectedEquipmentIds.contains(eq.id);
                  }).toList();
                  
                  if (availableEquipment.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  // Initialize checklist items if not already done
                  if (_checklistItems.isEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        for (var eq in availableEquipment) {
                          _checklistItems[eq.id] = _selectedEquipmentIds.contains(eq.id);
                        }
                      });
                    });
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verwendetes Equipment',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...availableEquipment.map((eq) {
                        // Check if equipment was available at jump date
                        final wasPurchased = eq.purchaseDate == null || 
                                           eq.purchaseDate!.isBefore(jumpDateTime) || 
                                           eq.purchaseDate!.isAtSameMomentAs(jumpDateTime);
                        final wasNotDeactivated = eq.deactivationDate == null || 
                                                 eq.deactivationDate!.isAfter(jumpDateTime);
                        final isAvailableAtJumpDate = wasPurchased && wasNotDeactivated;
                        
                        return CheckboxListTile(
                          title: Text(eq.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${eq.type.displayName}${eq.manufacturer != null ? ' - ${eq.manufacturer}' : ''}'),
                              if (!isAvailableAtJumpDate)
                                Text(
                                  '(Nicht verfügbar zum Sprungzeitpunkt)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[700],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                          value: _checklistItems[eq.id] ?? false,
                          onChanged: _isEditingMode ? (value) => _toggleEquipment(eq.id) : null,
                          enabled: _isEditingMode && (isAvailableAtJumpDate || _selectedEquipmentIds.contains(eq.id)),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Text('Fehler beim Laden: $error'),
              ),
              const SizedBox(height: 16),
              
              // Freefall Detection (for new jumps) or Display (for existing jumps)
              if (widget.jump == null)
                FreefallDetectionWidget(
                  onStatsUpdated: (stats) {
                    setState(() {
                      _freefallStats = stats;
                    });
                  },
                )
              else if (_freefallStats != null && _freefallStats!.hasData)
                _buildFreefallStatsDisplay(_freefallStats!),
              const SizedBox(height: 16),
              
              // Notes
              TextFormField(
                controller: _notesController,
                readOnly: !_isEditingMode,
                decoration: const InputDecoration(
                  labelText: 'Notizen',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              if (_isEditingMode) ...[
                const SizedBox(height: 24),
                
                // Save Button (only in editing mode)
                ElevatedButton(
                  onPressed: _saveJump,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(widget.jump != null ? 'Änderungen speichern' : 'Sprung speichern'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
