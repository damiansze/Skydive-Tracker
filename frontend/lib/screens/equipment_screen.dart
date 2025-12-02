import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/equipment.dart';
import '../providers/equipment_provider.dart';
import 'add_equipment_screen.dart';
import 'settings_screen.dart';

class EquipmentScreen extends ConsumerWidget {
  const EquipmentScreen({super.key});

  Widget _buildEquipmentCard(BuildContext context, WidgetRef ref, Equipment eq) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 8.0,
        vertical: 4.0,
      ),
      color: eq.isActive ? null : Colors.grey[200],
      child: ListTile(
        leading: Icon(
          _getEquipmentIcon(eq.type),
          color: eq.isActive ? null : Colors.grey[600],
        ),
        title: Text(
          eq.name,
          style: TextStyle(
            color: eq.isActive ? null : Colors.grey[600],
            decoration: eq.isActive ? null : TextDecoration.lineThrough,
          ),
        ),
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
            if (eq.deactivationDate != null)
              Text(
                'Deaktiviert am: ${DateFormat('dd.MM.yyyy').format(eq.deactivationDate!)}',
                style: TextStyle(color: Colors.grey[600]),
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
            PopupMenuItem(
              value: 'toggle_active',
              child: Row(
                children: [
                  Icon(eq.isActive ? Icons.visibility_off : Icons.visibility),
                  const SizedBox(width: 8),
                  Text(eq.isActive ? 'Deaktivieren' : 'Aktivieren'),
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
            } else if (value == 'toggle_active') {
              _toggleEquipmentActive(context, ref, eq);
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
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipmentAsync = ref.watch(equipmentNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Einstellungen',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: equipmentAsync.when(
        data: (equipment) {
          // Split equipment into active and inactive
          final activeEquipment = equipment.where((eq) => eq.isActive).toList();
          final inactiveEquipment = equipment.where((eq) => !eq.isActive).toList();
          
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
            child: ListView(
              padding: const EdgeInsets.all(8.0),
              children: [
                // Active Equipment Section
                if (activeEquipment.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Aktives Equipment',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...activeEquipment.map((eq) => _buildEquipmentCard(context, ref, eq)),
                ],
                
                // Inactive Equipment Section
                if (inactiveEquipment.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Deaktiviertes Equipment',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  ...inactiveEquipment.map((eq) => _buildEquipmentCard(context, ref, eq)),
                ],
              ],
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

  Future<void> _toggleEquipmentActive(
    BuildContext context,
    WidgetRef ref,
    Equipment equipment,
  ) async {
    try {
      // When deactivating, set deactivation_date to now
      // When activating, clear deactivation_date
      final updatedEquipment = equipment.copyWith(
        isActive: !equipment.isActive,
        deactivationDate: equipment.isActive ? DateTime.now() : null,
      );
      await ref.read(equipmentNotifierProvider.notifier).updateEquipment(updatedEquipment);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              equipment.isActive
                  ? 'Equipment deaktiviert'
                  : 'Equipment aktiviert',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Aktualisieren: $e')),
        );
      }
    }
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
        return Icons.paragliding;  // Better icon for parachute
      case EquipmentType.HARNESS:
        return Icons.safety_check;  // Better icon for harness/safety equipment
      case EquipmentType.RESERVE:
        return Icons.emergency_share;  // Better icon for reserve parachute
      case EquipmentType.ALTIMETER:
        return Icons.speed;  // Good icon for altimeter
      case EquipmentType.HELMET:
        return Icons.sports_motorsports;  // Good icon for helmet
      case EquipmentType.GOGGLES:
        return Icons.visibility;  // Good icon for goggles
      case EquipmentType.OTHER:
        return Icons.inventory_2;  // Good icon for other equipment
    }
  }
}
