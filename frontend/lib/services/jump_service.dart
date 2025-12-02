import '../models/jump.dart';
import '../models/equipment.dart';
import '../models/freefall_stats.dart';
import '../models/weather.dart';
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
    JumpType? jumpType,
    JumpMethod? jumpMethod,
    List<String> equipmentIds = const [],
    String? notes,
    FreefallStats? freefallStats,
    WeatherData? weather,
  }) async {
    final jump = await _api.createJump(
      date: date,
      location: location,
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      jumpType: jumpType,
      jumpMethod: jumpMethod,
      equipmentIds: equipmentIds,
      notes: notes,
      freefallStats: freefallStats,
      weather: weather,
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

  Future<int> getTotalJumps({
    String? locationFilter,
    String? jumpTypeFilter,
    String? jumpMethodFilter,
  }) async {
    return await _api.getTotalJumps(
      locationFilter: locationFilter,
      jumpTypeFilter: jumpTypeFilter,
      jumpMethodFilter: jumpMethodFilter,
    );
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
