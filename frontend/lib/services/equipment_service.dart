import 'package:uuid/uuid.dart';
import '../models/equipment.dart';
import 'database_service.dart';

class EquipmentService {
  final DatabaseService _db = DatabaseService();
  final _uuid = const Uuid();

  Future<String> createEquipment({
    required String name,
    required EquipmentType type,
    String? manufacturer,
    String? model,
    String? serialNumber,
    DateTime? purchaseDate,
    String? notes,
  }) async {
    final equipment = Equipment(
      id: _uuid.v4(),
      name: name,
      type: type,
      manufacturer: manufacturer,
      model: model,
      serialNumber: serialNumber,
      purchaseDate: purchaseDate,
      notes: notes,
    );

    await _db.insertEquipment(equipment);
    return equipment.id;
  }

  Future<List<Equipment>> getAllEquipment() async {
    return await _db.getAllEquipment();
  }

  Future<Equipment?> getEquipmentById(String id) async {
    return await _db.getEquipmentById(id);
  }

  Future<void> updateEquipment(Equipment equipment) async {
    await _db.updateEquipment(equipment);
  }

  Future<void> deleteEquipment(String id) async {
    await _db.deleteEquipment(id);
  }

  List<Equipment> filterByType(List<Equipment> equipment, EquipmentType type) {
    return equipment.where((e) => e.type == type).toList();
  }
}
