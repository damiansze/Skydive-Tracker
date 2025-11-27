import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import '../services/profile_service.dart';
import 'database_provider.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(ref.read(apiServiceProvider));
});

final profileProvider = FutureProvider<Profile?>((ref) async {
  final service = ref.read(profileServiceProvider);
  return await service.getProfile();
});

final profileNotifierProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<Profile?>>((ref) {
  return ProfileNotifier(ref.read(profileServiceProvider));
});

class ProfileNotifier extends StateNotifier<AsyncValue<Profile?>> {
  final ProfileService _service;

  ProfileNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _service.getProfile();
      state = AsyncValue.data(profile);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> createOrUpdateProfile(Profile profile) async {
    try {
      await _service.createOrUpdateProfile(profile);
      await _loadProfile();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateProfile(Profile profile) async {
    try {
      await _service.updateProfile(profile);
      await _loadProfile();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void refresh() {
    _loadProfile();
  }
}
