import '../models/profile.dart';
import 'api_service.dart';

class ProfileService {
  final ApiService _api;

  ProfileService(this._api);

  Future<String> createOrUpdateProfile(Profile profile) async {
    final updatedProfile = await _api.createOrUpdateProfile(profile);
    return updatedProfile.id;
  }

  Future<Profile?> getProfile() async {
    return await _api.getProfile();
  }

  Future<void> updateProfile(Profile profile) async {
    await _api.updateProfile(profile.copyWith(updatedAt: DateTime.now()));
  }
}
