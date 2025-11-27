import '../models/jump.dart';
import '../models/equipment.dart';
import '../models/profile.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // In-memory storage
  Profile? _profile;
  final List<Equipment> _equipment = [];
  final List<Jump> _jumps = [];
  final Map<String, List<String>> _jumpEquipment = {}; // jump_id -> equipment_ids

  // Profile methods
  Future<void> insertProfile(Profile profile) async {
    _profile = profile;
  }

  Future<Profile?> getProfile() async {
    return _profile;
  }

  Future<void> updateProfile(Profile profile) async {
    _profile = profile;
  }

  // Equipment methods
  Future<String> insertEquipment(Equipment equipment) async {
    _equipment.add(equipment);
    return equipment.id;
  }

  Future<List<Equipment>> getAllEquipment() async {
    return List.from(_equipment);
  }

  Future<Equipment?> getEquipmentById(String id) async {
    try {
      return _equipment.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateEquipment(Equipment equipment) async {
    final index = _equipment.indexWhere((e) => e.id == equipment.id);
    if (index != -1) {
      _equipment[index] = equipment;
    }
  }

  Future<void> deleteEquipment(String id) async {
    _equipment.removeWhere((e) => e.id == id);
    // Remove from jump associations
    _jumpEquipment.forEach((jumpId, equipmentIds) {
      equipmentIds.remove(id);
    });
  }

  // Jump methods
  Future<String> insertJump(Jump jump) async {
    _jumps.add(jump);
    _jumpEquipment[jump.id] = List.from(jump.equipmentIds);
    return jump.id;
  }

  Future<List<Jump>> getAllJumps({String? locationFilter}) async {
    List<Jump> jumps = List.from(_jumps);
    
    if (locationFilter != null && locationFilter.isNotEmpty) {
      jumps = jumps.where((j) => 
        j.location.toLowerCase().contains(locationFilter.toLowerCase())
      ).toList();
    }
    
    // Sort by date descending
    jumps.sort((a, b) => b.date.compareTo(a.date));
    
    // Load equipment IDs for each jump
    return jumps.map((jump) {
      final equipmentIds = _jumpEquipment[jump.id] ?? [];
      return jump.copyWith(equipmentIds: equipmentIds);
    }).toList();
  }

  Future<Jump?> getJumpById(String id) async {
    try {
      final jump = _jumps.firstWhere((j) => j.id == id);
      final equipmentIds = _jumpEquipment[jump.id] ?? [];
      return jump.copyWith(equipmentIds: equipmentIds);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateJump(Jump jump) async {
    final index = _jumps.indexWhere((j) => j.id == jump.id);
    if (index != -1) {
      _jumps[index] = jump;
      _jumpEquipment[jump.id] = List.from(jump.equipmentIds);
    }
  }

  Future<void> deleteJump(String id) async {
    _jumps.removeWhere((j) => j.id == id);
    _jumpEquipment.remove(id);
  }

  Future<int> getTotalJumps({String? locationFilter}) async {
    if (locationFilter != null && locationFilter.isNotEmpty) {
      return _jumps.where((j) => 
        j.location.toLowerCase().contains(locationFilter.toLowerCase())
      ).length;
    }
    return _jumps.length;
  }

  Future<List<String>> getDistinctLocations() async {
    final locations = _jumps.map((j) => j.location).toSet().toList();
    locations.sort();
    return locations;
  }
}
