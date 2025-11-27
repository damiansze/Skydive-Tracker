import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/equipment.dart';
import '../services/equipment_service.dart';
import 'add_equipment_screen.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  final EquipmentService _equipmentService = EquipmentService();
  List<Equipment> _equipment = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEquipment();
  }

  Future<void> _loadEquipment() async {
    setState(() {
      _isLoading = true;
    });

    final equipment = await _equipmentService.getAllEquipment();
    setState(() {
      _equipment = equipment;
      _isLoading = false;
    });
  }

  Future<void> _deleteEquipment(Equipment equipment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Equipment löschen'),
        content: Text('Möchten Sie "${equipment.name}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _equipmentService.deleteEquipment(equipment.id);
        await _loadEquipment();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Equipment gelöscht')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Löschen: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _equipment.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Noch kein Equipment vorhanden',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _equipment.length,
                  itemBuilder: (context, index) {
                    final equipment = _equipment[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: ListTile(
                        leading: Icon(_getEquipmentIcon(equipment.type)),
                        title: Text(equipment.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Typ: ${equipment.type.displayName}'),
                            if (equipment.manufacturer != null)
                              Text('Hersteller: ${equipment.manufacturer}'),
                            if (equipment.model != null)
                              Text('Modell: ${equipment.model}'),
                            if (equipment.serialNumber != null)
                              Text('Seriennummer: ${equipment.serialNumber}'),
                            if (equipment.purchaseDate != null)
                              Text(
                                'Kaufdatum: ${DateFormat('dd.MM.yyyy').format(equipment.purchaseDate!)}',
                              ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Bearbeiten'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Löschen', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddEquipmentScreen(
                                    equipment: equipment,
                                  ),
                                ),
                              ).then((_) => _loadEquipment());
                            } else if (value == 'delete') {
                              _deleteEquipment(equipment);
                            }
                          },
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddEquipmentScreen(
                                equipment: equipment,
                              ),
                            ),
                          ).then((_) => _loadEquipment());
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEquipmentScreen(),
            ),
          ).then((_) => _loadEquipment());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getEquipmentIcon(EquipmentType type) {
    switch (type) {
      case EquipmentType.PARACHUTE:
        return Icons.airplanemode_active;
      case EquipmentType.HARNESS:
        return Icons.safety_divider;
      case EquipmentType.RESERVE:
        return Icons.emergency;
      case EquipmentType.ALTIMETER:
        return Icons.speed;
      case EquipmentType.HELMET:
        return Icons.sports_motorsports;
      case EquipmentType.GOGGLES:
        return Icons.visibility;
      case EquipmentType.OTHER:
        return Icons.inventory_2;
    }
  }
}
