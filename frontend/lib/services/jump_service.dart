import 'package:uuid/uuid.dart';
import '../models/jump.dart';
import '../models/equipment.dart';
import 'database_service.dart';

class JumpService {
  final DatabaseService _db = DatabaseService();
  final _uuid = const Uuid();

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
    final jump = Jump(
      id: _uuid.v4(),
      date: date,
      location: location,
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      equipmentIds: equipmentIds,
      checklistCompleted: checklistCompleted,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await _db.insertJump(jump);
    
    // Update profile total jumps
    final profile = await _db.getProfile();
    if (profile != null) {
      await _db.updateProfile(profile.copyWith(
        totalJumps: profile.totalJumps + 1,
        updatedAt: DateTime.now(),
      ));
    }

    return jump.id;
  }

  Future<List<Jump>> getAllJumps({String? locationFilter}) async {
    return await _db.getAllJumps(locationFilter: locationFilter);
  }

  Future<Jump?> getJumpById(String id) async {
    return await _db.getJumpById(id);
  }

  Future<void> updateJump(Jump jump) async {
    await _db.updateJump(jump);
  }

  Future<void> deleteJump(String id) async {
    await _db.deleteJump(id);
    
    // Update profile total jumps
    final profile = await _db.getProfile();
    if (profile != null && profile.totalJumps > 0) {
      await _db.updateProfile(profile.copyWith(
        totalJumps: profile.totalJumps - 1,
        updatedAt: DateTime.now(),
      ));
    }
  }

  Future<int> getTotalJumps({String? locationFilter}) async {
    return await _db.getTotalJumps(locationFilter: locationFilter);
  }

  Future<List<String>> getDistinctLocations() async {
    return await _db.getDistinctLocations();
  }

  Future<List<Equipment>> getJumpEquipment(String jumpId) async {
    final jump = await getJumpById(jumpId);
    if (jump == null) return [];
    
    final allEquipment = await _db.getAllEquipment();
    return allEquipment.where((e) => jump.equipmentIds.contains(e.id)).toList();
  }
}
