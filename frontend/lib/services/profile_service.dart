import 'package:uuid/uuid.dart';
import '../models/profile.dart';
import 'database_service.dart';

class ProfileService {
  final DatabaseService _db;

  ProfileService(this._db);
  final _uuid = const Uuid();

  Future<String> createOrUpdateProfile(Profile profile) async {
    final existingProfile = await _db.getProfile();
    
    if (existingProfile != null) {
      final updatedProfile = profile.copyWith(
        id: existingProfile.id,
        totalJumps: existingProfile.totalJumps,
        createdAt: existingProfile.createdAt,
        updatedAt: DateTime.now(),
      );
      await _db.updateProfile(updatedProfile);
      return updatedProfile.id;
    } else {
      final newProfile = profile.copyWith(
        id: _uuid.v4(),
        totalJumps: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _db.insertProfile(newProfile);
      return newProfile.id;
    }
  }

  Future<Profile?> getProfile() async {
    return await _db.getProfile();
  }

  Future<void> updateProfile(Profile profile) async {
    await _db.updateProfile(profile.copyWith(updatedAt: DateTime.now()));
  }
}
