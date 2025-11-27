import 'package:uuid/uuid.dart';
import '../models/profile.dart';
import 'database_service.dart';

class ProfileService {
  final DatabaseService _db = DatabaseService();
  final _uuid = const Uuid();

  Future<String> createOrUpdateProfile({
    required String name,
    String? licenseNumber,
    String? licenseType,
  }) async {
    final existingProfile = await _db.getProfile();
    
    if (existingProfile != null) {
      final updatedProfile = existingProfile.copyWith(
        name: name,
        licenseNumber: licenseNumber,
        licenseType: licenseType,
        updatedAt: DateTime.now(),
      );
      await _db.updateProfile(updatedProfile);
      return updatedProfile.id;
    } else {
      final profile = Profile(
        id: _uuid.v4(),
        name: name,
        licenseNumber: licenseNumber,
        licenseType: licenseType,
        totalJumps: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _db.insertProfile(profile);
      return profile.id;
    }
  }

  Future<Profile?> getProfile() async {
    return await _db.getProfile();
  }

  Future<void> updateProfile(Profile profile) async {
    await _db.updateProfile(profile.copyWith(updatedAt: DateTime.now()));
  }
}
