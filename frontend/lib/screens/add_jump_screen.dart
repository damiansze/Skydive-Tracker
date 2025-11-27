import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/jump.dart';
import '../models/equipment.dart';
import '../services/jump_service.dart';
import '../services/equipment_service.dart';

class AddJumpScreen extends StatefulWidget {
  final Jump? jump; // For editing existing jumps

  const AddJumpScreen({super.key, this.jump});

  @override
  State<AddJumpScreen> createState() => _AddJumpScreenState();
}

class _AddJumpScreenState extends State<AddJumpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _altitudeController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  double? _latitude;
  double? _longitude;
  LatLng? _mapCenter;
  final MapController _mapController = MapController();
  
  List<Equipment> _allEquipment = [];
  Set<String> _selectedEquipmentIds = {};
  Map<String, bool> _checklistItems = {};

  final JumpService _jumpService = JumpService();
  final EquipmentService _equipmentService = EquipmentService();

  @override
  void initState() {
    super.initState();
    _loadEquipment();
    if (widget.jump != null) {
      _loadJumpData();
    } else {
      _getCurrentLocation();
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
    _selectedEquipmentIds = jump.equipmentIds.toSet();
    
    if (_latitude != null && _longitude != null) {
      _mapCenter = LatLng(_latitude!, _longitude!);
    }
  }

  Future<void> _loadEquipment() async {
    final equipment = await _equipmentService.getAllEquipment();
    setState(() {
      _allEquipment = equipment;
      _initializeChecklist();
    });
  }

  void _initializeChecklist() {
    for (var equipment in _allEquipment) {
      _checklistItems[equipment.id] = _selectedEquipmentIds.contains(equipment.id);
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
        _mapCenter = LatLng(_latitude!, _longitude!);
        _mapController.move(_mapCenter!, 13.0);
      });
    } catch (e) {
      // Location not available
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
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _latitude = point.latitude;
      _longitude = point.longitude;
      _mapController.move(point, _mapController.camera.zoom);
    });
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
      if (widget.jump != null) {
        final updatedJump = widget.jump!.copyWith(
          date: dateTime,
          location: _locationController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          altitude: int.parse(_altitudeController.text),
          equipmentIds: _selectedEquipmentIds.toList(),
          checklistCompleted: _checklistItems.values.every((v) => v),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
        await _jumpService.updateJump(updatedJump);
      } else {
        await _jumpService.createJump(
          date: dateTime,
          location: _locationController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          altitude: int.parse(_altitudeController.text),
          equipmentIds: _selectedEquipmentIds.toList(),
          checklistCompleted: _checklistItems.values.every((v) => v),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      }

      if (mounted) {
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
    _locationController.dispose();
    _altitudeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.jump != null ? 'Sprung bearbeiten' : 'Neuer Sprung'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
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
            
            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Ort *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bitte geben Sie einen Ort ein';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Map
            if (_mapCenter != null)
              SizedBox(
                height: 300,
                child: Card(
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Position auf Karte auswählen',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _mapCenter!,
                            initialZoom: 13.0,
                            onTap: _onMapTap,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.flutter_skydive_tracker',
                            ),
                            if (_latitude != null && _longitude != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(_latitude!, _longitude!),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            
            // Altitude
            TextFormField(
              controller: _altitudeController,
              decoration: const InputDecoration(
                labelText: 'Höhe (ft) *',
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
            
            // Equipment Checklist
            if (_allEquipment.isNotEmpty) ...[
              const Text(
                'Equipment Checkliste',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._allEquipment.map((equipment) {
                return CheckboxListTile(
                  title: Text(equipment.name),
                  subtitle: Text('${equipment.type.displayName}${equipment.manufacturer != null ? ' - ${equipment.manufacturer}' : ''}'),
                  value: _checklistItems[equipment.id] ?? false,
                  onChanged: (value) => _toggleEquipment(equipment.id),
                );
              }),
              const SizedBox(height: 16),
            ],
            
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
    );
  }
}
