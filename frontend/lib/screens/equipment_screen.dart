import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/equipment.dart';
import '../providers/equipment_provider.dart';
import 'add_equipment_screen.dart';

class EquipmentScreen extends ConsumerWidget {
  const EquipmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipmentAsync = ref.watch(equipmentNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment'),
      ),
      body: equipmentAsync.when(
        data: (equipment) {
          if (equipment.isEmpty) {
            return Center(
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
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.read(equipmentNotifierProvider.notifier).refresh();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: equipment.length,
              itemBuilder: (context, index) {
                final eq = equipment[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: ListTile(
                    leading: Icon(_getEquipmentIcon(eq.type)),
                    title: Text(eq.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Typ: ${eq.type.displayName}'),
                        if (eq.manufacturer != null)
                          Text('Hersteller: ${eq.manufacturer}'),
                        if (eq.model != null) Text('Modell: ${eq.model}'),
                        if (eq.serialNumber != null)
                          Text('Seriennummer: ${eq.serialNumber}'),
                        if (eq.purchaseDate != null)
                          Text(
                            'Kaufdatum: ${DateFormat('dd.MM.yyyy').format(eq.purchaseDate!)}',
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
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddEquipmentScreen(
                                equipment: eq,
                              ),
                            ),
                          );
                          ref.read(equipmentNotifierProvider.notifier).refresh();
                        } else if (value == 'delete') {
                          _deleteEquipment(context, ref, eq);
                        }
                      },
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddEquipmentScreen(
                            equipment: eq,
                          ),
                        ),
                      );
                      ref.read(equipmentNotifierProvider.notifier).refresh();
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Fehler: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(equipmentNotifierProvider.notifier).refresh();
                },
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEquipmentScreen(),
            ),
          );
          ref.read(equipmentNotifierProvider.notifier).refresh();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _deleteEquipment(
    BuildContext context,
    WidgetRef ref,
    Equipment equipment,
  ) async {
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
        await ref.read(equipmentNotifierProvider.notifier).deleteEquipment(equipment.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Equipment gelöscht')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Löschen: $e')),
          );
        }
      }
    }
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
