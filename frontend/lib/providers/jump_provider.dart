import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/jump.dart';
import '../services/jump_service.dart';
import 'database_provider.dart';
import 'profile_provider.dart';

final jumpServiceProvider = Provider<JumpService>((ref) {
  return JumpService(ref.read(apiServiceProvider));
});

final jumpListProvider = FutureProvider.family<List<Jump>, String?>((ref, locationFilter) async {
  final service = ref.read(jumpServiceProvider);
  return await service.getAllJumps(locationFilter: locationFilter);
});

final jumpNotifierProvider = StateNotifierProvider<JumpNotifier, AsyncValue<List<Jump>>>((ref) {
  return JumpNotifier(ref.read(jumpServiceProvider), ref);
});

class JumpNotifier extends StateNotifier<AsyncValue<List<Jump>>> {
  final JumpService _service;
  final Ref _ref;
  String? _locationFilter;

  JumpNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
    _loadJumps();
  }

  Future<void> _loadJumps() async {
    try {
      final jumps = await _service.getAllJumps(locationFilter: _locationFilter);
      state = AsyncValue.data(jumps);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> createJump({
    required DateTime date,
    required String location,
    double? latitude,
    double? longitude,
    required int altitude,
    List<String> equipmentIds = const [],
    bool checklistCompleted = false,
    String? notes,
  }) async {
    try {
      await _service.createJump(
        date: date,
        location: location,
        latitude: latitude,
        longitude: longitude,
        altitude: altitude,
        equipmentIds: equipmentIds,
        checklistCompleted: checklistCompleted,
        notes: notes,
      );
      await _loadJumps();
      // Refresh profile to update total jumps count
      _ref.read(profileNotifierProvider.notifier).refresh();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateJump(Jump jump) async {
    try {
      await _service.updateJump(jump);
      await _loadJumps();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteJump(String id) async {
    try {
      await _service.deleteJump(id);
      await _loadJumps();
      // Refresh profile to update total jumps count
      _ref.read(profileNotifierProvider.notifier).refresh();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void setLocationFilter(String? filter) {
    _locationFilter = filter;
    _loadJumps();
  }

  void refresh() {
    _loadJumps();
  }
}
