import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/equipment.dart';
import '../services/equipment_service.dart';
import 'database_provider.dart';

final equipmentServiceProvider = Provider<EquipmentService>((ref) {
  return EquipmentService(ref.read(apiServiceProvider));
});

final equipmentListProvider = FutureProvider<List<Equipment>>((ref) async {
  final service = ref.read(equipmentServiceProvider);
  return await service.getAllEquipment();
});

final equipmentNotifierProvider = StateNotifierProvider<EquipmentNotifier, AsyncValue<List<Equipment>>>((ref) {
  return EquipmentNotifier(ref.read(equipmentServiceProvider));
});

class EquipmentNotifier extends StateNotifier<AsyncValue<List<Equipment>>> {
  final EquipmentService _service;

  EquipmentNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadEquipment();
  }

  Future<void> _loadEquipment() async {
    try {
      final equipment = await _service.getAllEquipment();
      state = AsyncValue.data(equipment);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> createEquipment(Equipment equipment) async {
    try {
      await _service.createEquipment(
        name: equipment.name,
        type: equipment.type,
        manufacturer: equipment.manufacturer,
        model: equipment.model,
        serialNumber: equipment.serialNumber,
        purchaseDate: equipment.purchaseDate,
        reminderAfterJumps: equipment.reminderAfterJumps,
        notes: equipment.notes,
      );
      await _loadEquipment();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateEquipment(Equipment equipment) async {
    try {
      await _service.updateEquipment(equipment);
      await _loadEquipment();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteEquipment(String id) async {
    try {
      await _service.deleteEquipment(id);
      await _loadEquipment();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void refresh() {
    _loadEquipment();
  }
}
