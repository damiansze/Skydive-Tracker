import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/jump.dart';
import '../models/equipment.dart';
import '../providers/jump_provider.dart';
import '../providers/equipment_provider.dart';
import '../services/geocoding_service.dart';
import 'map_location_picker_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.jump != null) {
      _loadJumpData();
    } else {
      _getCurrentLocation();
    }
    
    // Listen to location field changes for geocoding
    _locationController.addListener(_onLocationChanged);
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
    
    if (_latitude != null && _longitude != null) {
      _currentLocation = LatLng(_latitude!, _longitude!);
    }
  }

  Future<void> _getCurrentLocation() async {
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
      
      // Get address for current location
      final address = await GeocodingService.getAddressFromCoordinates(_currentLocation!);
      if (address != null && mounted) {
        _locationController.text = address;
      }
    } catch (e) {
      // Location not available
    }
  }

  Future<void> _onLocationChanged() async {
    final locationText = _locationController.text.trim();
    
    // Get suggestions for autocomplete
    if (locationText.length >= 3) {
      final suggestions = await GeocodingService.getAddressSuggestions(locationText);
      if (mounted) {
        setState(() {
          _locationSuggestions = suggestions;
          _showSuggestions = suggestions.isNotEmpty;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _locationSuggestions = [];
          _showSuggestions = false;
        });
      }
    }
    
    // Debounce geocoding to avoid too many API calls
    if (_isGeocoding) return;
    
    if (locationText.length < 3) return; // Wait for at least 3 characters
    
    // Wait a bit before geocoding
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Check if text hasn't changed during delay
    if (_locationController.text.trim() != locationText) return;
    
    setState(() {
      _isGeocoding = true;
    });
    
    try {
      final coordinates = await GeocodingService.getCoordinatesFromAddress(locationText);
      if (coordinates != null && mounted) {
        setState(() {
          _latitude = coordinates.latitude;
          _longitude = coordinates.longitude;
          _currentLocation = coordinates;
        });
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
  
  void _selectLocationSuggestion(String suggestion) {
    setState(() {
      _locationController.text = suggestion;
      _showSuggestions = false;
      _locationSuggestions = [];
    });
    // Trigger geocoding for selected suggestion
    _onLocationChanged();
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

    if (result != null) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _currentLocation = result;
      });
      
      // Get address for selected location
      final address = await GeocodingService.getAddressFromCoordinates(result);
      if (address != null && mounted) {
        _locationController.text = address;
      }
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
          checklistCompleted: _checklistItems.values.every((v) => v),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
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
          checklistCompleted: _selectedEquipmentIds.isNotEmpty, // Equipment was selected
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      }

      if (mounted) {
        // Refresh statistics providers
        ref.invalidate(distinctLocationsProvider);
        ref.invalidate(totalJumpsProvider);
        ref.invalidate(statisticsSummaryProvider);
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

  @override
  void dispose() {
    _locationController.removeListener(_onLocationChanged);
    _locationController.dispose();
    _altitudeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final equipmentAsync = ref.watch(equipmentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.jump != null ? 'Sprung bearbeiten' : 'Neuer Sprung'),
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
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _selectDate,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Uhrzeit'),
                  subtitle: Text(_selectedTime.format(context)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _selectTime,
                ),
              ),
              const SizedBox(height: 16),
              
              // Location with Autocomplete
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Ort *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.location_on),
                      suffixIcon: _isGeocoding
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
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Bitte geben Sie einen Ort ein';
                      }
                      return null;
                    },
                    onTap: () {
                      setState(() {
                        if (_locationController.text.length >= 3) {
                          _showSuggestions = _locationSuggestions.isNotEmpty;
                        }
                      });
                    },
                    onChanged: (value) {
                      _onLocationChanged();
                    },
                    onTapOutside: (event) {
                      // Hide suggestions when tapping outside
                      setState(() {
                        _showSuggestions = false;
                      });
                    },
                  ),
                  if (_showSuggestions && _locationSuggestions.isNotEmpty)
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
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on, size: 20),
                            title: Text(
                              suggestion,
                              style: const TextStyle(fontSize: 14),
                            ),
                            onTap: () {
                              _selectLocationSuggestion(suggestion);
                            },
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
                  onTap: _openMapPicker,
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
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
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
                onChanged: (value) {
                  setState(() {
                    _selectedJumpType = value;
                  });
                },
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
                onChanged: (value) {
                  setState(() {
                    _selectedJumpMethod = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Altitude
              TextFormField(
                controller: _altitudeController,
                decoration: const InputDecoration(
                  labelText: 'Höhe (m) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.height),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte geben Sie eine Höhe ein';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Bitte geben Sie eine gültige Höhe ein';
                  }
                  return null;
                },
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
                          onChanged: (value) => _toggleEquipment(eq.id),
                          enabled: isAvailableAtJumpDate || _selectedEquipmentIds.contains(eq.id),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Text('Fehler beim Laden: $error'),
              ),
              
              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notizen',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              // Save Button
              ElevatedButton(
                onPressed: _saveJump,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(widget.jump != null ? 'Änderungen speichern' : 'Sprung speichern'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
