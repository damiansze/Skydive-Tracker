import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/jump.dart';
import '../models/equipment.dart';
import '../models/profile.dart';
import '../models/freefall_stats.dart';
import '../models/weather.dart';
import '../config/api_config.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;
  
  // Helper method for GET requests - returns dynamic to handle both Map and List
  Future<dynamic> _get(String endpoint) async {
    final url = '$baseUrl$endpoint';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Not found: ${response.statusCode}');
      } else {
        final errorBody = response.body;
        throw Exception('Failed to load: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      if (e.toString().contains('Failed to load') || e.toString().contains('Exception')) {
        rethrow;
      }
      throw Exception('Network error: $e');
    }
  }

  // Helper method for GET requests that return a Map
  Future<Map<String, dynamic>> _getMap(String endpoint) async {
    final result = await _get(endpoint);
    if (result is Map<String, dynamic>) {
      return result;
    } else {
      throw Exception('Expected Map but got ${result.runtimeType}');
    }
  }

  // Helper method for GET requests that return a List
  Future<List<dynamic>> _getList(String endpoint) async {
    final result = await _get(endpoint);
    if (result is List) {
      return result;
    } else {
      throw Exception('Expected List but got ${result.runtimeType}');
    }
  }

  // Helper method for POST requests
  Future<dynamic> _post(String endpoint, Map<String, dynamic> data) async {
    final url = '$baseUrl$endpoint';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create: ${response.statusCode}');
    }
  }

  // Helper method for PUT requests
  Future<dynamic> _put(String endpoint, Map<String, dynamic> data) async {
    final url = '$baseUrl$endpoint';
    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update: ${response.statusCode}');
    }
  }

  // Helper method for DELETE requests
  Future<void> _delete(String endpoint) async {
    final url = '$baseUrl$endpoint';
    final response = await http.delete(Uri.parse(url));
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete: ${response.statusCode}');
    }
  }

  // Profile methods
  Future<Profile?> getProfile() async {
    try {
      final data = await _getMap('/profile/');
      return Profile.fromMap(data);
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('404') || errorStr.contains('not found')) {
        return null;
      }
      // Log other errors but don't crash
      print('Error fetching profile: $e');
      rethrow;
    }
  }

  Future<Profile> createOrUpdateProfile(Profile profile) async {
    final profileMap = profile.toMap();
    profileMap.remove('id'); // Remove id for create/update
    profileMap.remove('total_jumps'); // Remove total_jumps - backend calculates it
    profileMap.remove('created_at'); // Remove created_at
    profileMap.remove('updated_at'); // Remove updated_at
    final data = await _post('/profile/', profileMap) as Map<String, dynamic>;
    return Profile.fromMap(data);
  }

  Future<Profile> updateProfile(Profile profile) async {
    final profileMap = profile.toMap();
    profileMap.remove('id'); // Remove id - backend doesn't need it
    profileMap.remove('total_jumps'); // Remove total_jumps - backend calculates it
    profileMap.remove('created_at'); // Remove created_at
    profileMap.remove('updated_at'); // Remove updated_at
    final data = await _put('/profile/', profileMap) as Map<String, dynamic>;
    return Profile.fromMap(data);
  }

  Future<String> uploadProfilePicture(String imagePath) async {
    final url = '$baseUrl/profile/upload-picture';
    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.files.add(await http.MultipartFile.fromPath('file', imagePath));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final relativeUrl = data['profile_picture_url'] as String;
      // Return only the relative URL - the full URL will be constructed
      // dynamically when displaying the image based on the current platform
      // This ensures images work on both iOS and Android
      return relativeUrl;
    } else {
      final errorBody = response.body;
      throw Exception('Failed to upload picture: ${response.statusCode} - $errorBody');
    }
  }

  // Equipment methods
  Future<List<Equipment>> getAllEquipment() async {
    final List<dynamic> data = await _getList('/equipment/');
    return data.map((e) => Equipment.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<Equipment?> getEquipmentById(String id) async {
    try {
      final data = await _getMap('/equipment/$id');
      return Equipment.fromMap(data);
    } catch (e) {
      if (e.toString().contains('404')) {
        return null;
      }
      rethrow;
    }
  }

  Future<Equipment> createEquipment(Equipment equipment) async {
    final equipmentMap = equipment.toMap();
    equipmentMap.remove('id'); // Remove id for creation
    equipmentMap.remove('created_at'); // Remove created_at for creation
    final data = await _post('/equipment/', equipmentMap) as Map<String, dynamic>;
    return Equipment.fromMap(data);
  }

  Future<Equipment> updateEquipment(Equipment equipment) async {
    final equipmentMap = equipment.toMap();
    equipmentMap.remove('created_at'); // Keep id but remove created_at
    final data = await _put('/equipment/${equipment.id}', equipmentMap) as Map<String, dynamic>;
    return Equipment.fromMap(data);
  }

  Future<void> deleteEquipment(String id) async {
    await _delete('/equipment/$id');
  }

  // Jump methods
  Future<List<Jump>> getAllJumps({String? locationFilter}) async {
    final List<dynamic> data = await _getList('/jumps/');
    List<Jump> jumps = data.map((e) => Jump.fromMap(e as Map<String, dynamic>)).toList();
    if (locationFilter != null && locationFilter.isNotEmpty) {
      jumps = jumps.where((j) => j.location.toLowerCase().contains(locationFilter.toLowerCase())).toList();
    }
    return jumps;
  }

  Future<Jump?> getJumpById(String id) async {
    try {
      final data = await _getMap('/jumps/$id');
      return Jump.fromMap(data);
    } catch (e) {
      if (e.toString().contains('404')) {
        return null;
      }
      rethrow;
    }
  }

  Future<Jump> createJump({
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
    final jumpMap = {
      'date': date.toIso8601String(),
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'jump_type': jumpType?.toString().split('.').last.toLowerCase(),
      'jump_method': jumpMethod?.toString().split('.').last.toLowerCase(),
      'equipment_ids': equipmentIds,
      'notes': notes,
      if (freefallStats != null) 'freefall_stats': freefallStats.toMap(),
      if (weather != null) 'weather': weather.toMap(),
    };
    final data = await _post('/jumps/', jumpMap) as Map<String, dynamic>;
    return Jump.fromMap(data);
  }

  Future<Jump> updateJump(Jump jump) async {
    final jumpMap = {
      'date': jump.date.toIso8601String(),
      'location': jump.location,
      'latitude': jump.latitude,
      'longitude': jump.longitude,
      'altitude': jump.altitude,
      'jump_type': jump.jumpType?.toString().split('.').last.toLowerCase(),
      'jump_method': jump.jumpMethod?.toString().split('.').last.toLowerCase(),
      'equipment_ids': jump.equipmentIds,
      'notes': jump.notes,
      if (jump.freefallStats != null) 'freefall_stats': jump.freefallStats!.toMap(),
      if (jump.weather != null) 'weather': jump.weather!.toMap(),
    };
    final data = await _put('/jumps/${jump.id}', jumpMap) as Map<String, dynamic>;
    return Jump.fromMap(data);
  }

  Future<void> deleteJump(String id) async {
    await _delete('/jumps/$id');
  }

  // Statistics methods
  Future<int> getTotalJumps({
    String? locationFilter,
    String? jumpTypeFilter,
    String? jumpMethodFilter,
  }) async {
    final params = <String>[];
    if (locationFilter != null) params.add('location=$locationFilter');
    if (jumpTypeFilter != null) params.add('jump_type=$jumpTypeFilter');
    if (jumpMethodFilter != null) params.add('jump_method=$jumpMethodFilter');
    final queryParam = params.isNotEmpty ? '?${params.join('&')}' : '';
    final data = await _getMap('/statistics/total-jumps$queryParam');
    return data['total_jumps'] as int;
  }

  Future<List<String>> getDistinctLocations() async {
    final data = await _getMap('/statistics/summary');
    final locations = data['locations'] as List<dynamic>;
    return locations.map((e) => e as String).toList();
  }

  Future<Map<String, dynamic>> getStatisticsSummary({
    String? locationFilter,
    String? jumpTypeFilter,
    String? jumpMethodFilter,
  }) async {
    final params = <String>[];
    if (locationFilter != null) params.add('location=$locationFilter');
    if (jumpTypeFilter != null) params.add('jump_type=$jumpTypeFilter');
    if (jumpMethodFilter != null) params.add('jump_method=$jumpMethodFilter');
    final queryParam = params.isNotEmpty ? '?${params.join('&')}' : '';
    return await _getMap('/statistics/summary$queryParam');
  }
}
