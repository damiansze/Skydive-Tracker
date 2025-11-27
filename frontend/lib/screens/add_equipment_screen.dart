import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/equipment.dart';
import '../services/equipment_service.dart';

class AddEquipmentScreen extends StatefulWidget {
  final Equipment? equipment;

  const AddEquipmentScreen({super.key, this.equipment});

  @override
  State<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends State<AddEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _notesController = TextEditingController();
  
  EquipmentType _selectedType = EquipmentType.OTHER;
  DateTime? _purchaseDate;

  final EquipmentService _equipmentService = EquipmentService();

  @override
  void initState() {
    super.initState();
    if (widget.equipment != null) {
      _loadEquipmentData();
    }
  }

  void _loadEquipmentData() {
    final equipment = widget.equipment!;
    _nameController.text = equipment.name;
    _selectedType = equipment.type;
    _manufacturerController.text = equipment.manufacturer ?? '';
    _modelController.text = equipment.model ?? '';
    _serialNumberController.text = equipment.serialNumber ?? '';
    _purchaseDate = equipment.purchaseDate;
    _notesController.text = equipment.notes ?? '';
  }

  Future<void> _selectPurchaseDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _purchaseDate) {
      setState(() {
        _purchaseDate = picked;
      });
    }
  }

  Future<void> _saveEquipment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      if (widget.equipment != null) {
        final updatedEquipment = widget.equipment!.copyWith(
          name: _nameController.text.trim(),
          type: _selectedType,
          manufacturer: _manufacturerController.text.trim().isEmpty
              ? null
              : _manufacturerController.text.trim(),
          model: _modelController.text.trim().isEmpty
              ? null
              : _modelController.text.trim(),
          serialNumber: _serialNumberController.text.trim().isEmpty
              ? null
              : _serialNumberController.text.trim(),
          purchaseDate: _purchaseDate,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
        await _equipmentService.updateEquipment(updatedEquipment);
      } else {
        await _equipmentService.createEquipment(
          name: _nameController.text.trim(),
          type: _selectedType,
          manufacturer: _manufacturerController.text.trim().isEmpty
              ? null
              : _manufacturerController.text.trim(),
          model: _modelController.text.trim().isEmpty
              ? null
              : _modelController.text.trim(),
          serialNumber: _serialNumberController.text.trim().isEmpty
              ? null
              : _serialNumberController.text.trim(),
          purchaseDate: _purchaseDate,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
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
    _nameController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    _serialNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.equipment != null ? 'Equipment bearbeiten' : 'Neues Equipment'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bitte geben Sie einen Namen ein';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Type
            DropdownButtonFormField<EquipmentType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Typ *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: EquipmentType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Manufacturer
            TextFormField(
              controller: _manufacturerController,
              decoration: const InputDecoration(
                labelText: 'Hersteller',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 16),
            
            // Model
            TextFormField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'Modell',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2),
              ),
            ),
            const SizedBox(height: 16),
            
            // Serial Number
            TextFormField(
              controller: _serialNumberController,
              decoration: const InputDecoration(
                labelText: 'Seriennummer',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code),
              ),
            ),
            const SizedBox(height: 16),
            
            // Purchase Date
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Kaufdatum'),
                subtitle: Text(
                  _purchaseDate != null
                      ? DateFormat('dd.MM.yyyy').format(_purchaseDate!)
                      : 'Nicht angegeben',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectPurchaseDate,
              ),
            ),
            const SizedBox(height: 16),
            
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
              onPressed: _saveEquipment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(widget.equipment != null ? 'Änderungen speichern' : 'Equipment speichern'),
            ),
          ],
        ),
      ),
    );
  }
}
