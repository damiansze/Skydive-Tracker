import '../models/jump.dart';
import '../models/equipment.dart';
import 'api_service.dart';

class JumpService {
  final ApiService _api;

  JumpService(this._api);

  Future<String> createJump({
    required DateTime date,
    required String location,
    double? latitude,
    double? longitude,
    required int altitude,
    List<String> equipmentIds = const [],
    bool checklistCompleted = false,
    String? notes,
  }) async {
    final jump = await _api.createJump(
      date: date,
      location: location,
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      equipmentIds: equipmentIds,
      checklistCompleted: checklistCompleted,
      notes: notes,
    );
    return jump.id;
  }

  Future<List<Jump>> getAllJumps({String? locationFilter}) async {
    return await _api.getAllJumps(locationFilter: locationFilter);
  }

  Future<Jump?> getJumpById(String id) async {
    return await _api.getJumpById(id);
  }

  Future<void> updateJump(Jump jump) async {
    await _api.updateJump(jump);
  }

  Future<void> deleteJump(String id) async {
    await _api.deleteJump(id);
  }

  Future<int> getTotalJumps({String? locationFilter}) async {
    return await _api.getTotalJumps(locationFilter: locationFilter);
  }

  Future<List<String>> getDistinctLocations() async {
    return await _api.getDistinctLocations();
  }

  Future<List<Equipment>> getJumpEquipment(String jumpId) async {
    final jump = await getJumpById(jumpId);
    if (jump == null) return [];
    
    final allEquipment = await _api.getAllEquipment();
    return allEquipment.where((e) => jump.equipmentIds.contains(e.id)).toList();
  }
}
