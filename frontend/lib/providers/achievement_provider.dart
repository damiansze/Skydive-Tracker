import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/achievement.dart';
import '../models/jump.dart';
import 'jump_provider.dart';

final achievementProvider = FutureProvider<List<Achievement>>((ref) async {
  final jumpsAsync = ref.watch(jumpNotifierProvider);
  
  return jumpsAsync.when(
    data: (jumps) => _calculateAchievements(jumps),
    loading: () => [],
    error: (_, __) => [],
  );
});

List<Achievement> _calculateAchievements(List<Jump> jumps) {
  final achievements = <Achievement>[];
  
  // First Jump Achievement
  final firstJumpAchievement = Achievement(
    type: AchievementType.FIRST_JUMP,
    title: 'Erster Sprung',
    description: 'Du hast deinen ersten Sprung absolviert!',
    icon: '🎉',
    unlocked: jumps.isNotEmpty,
    unlockedAt: jumps.isNotEmpty ? jumps.first.date : null,
  );
  achievements.add(firstJumpAchievement);
  
  // Five Locations Achievement
  final uniqueLocations = jumps.map((j) => j.location).toSet();
  final fiveLocationsAchievement = Achievement(
    type: AchievementType.FIVE_LOCATIONS,
    title: '5 Sprungplätze',
    description: 'Du hast von 5 verschiedenen Sprungplätzen gesprungen!',
    icon: '🌍',
    unlocked: uniqueLocations.length >= 5,
    unlockedAt: uniqueLocations.length >= 5 ? jumps.last.date : null,
  );
  achievements.add(fiveLocationsAchievement);
  
  // First Helicopter Achievement
  final hasHelicopterJump = jumps.any((j) => j.jumpType == JumpType.HELICOPTER);
  final firstHelicopterAchievement = Achievement(
    type: AchievementType.FIRST_HELICOPTER,
    title: 'Erstes Mal Helikopter',
    description: 'Du hast deinen ersten Helikopter-Sprung gemacht!',
    icon: '🚁',
    unlocked: hasHelicopterJump,
    unlockedAt: hasHelicopterJump 
        ? jumps.firstWhere((j) => j.jumpType == JumpType.HELICOPTER).date 
        : null,
  );
  achievements.add(firstHelicopterAchievement);
  
  // First Plane Achievement
  final hasPlaneJump = jumps.any((j) => j.jumpType == JumpType.PLANE);
  final firstPlaneAchievement = Achievement(
    type: AchievementType.FIRST_PLANE,
    title: 'Erstes Mal Flugzeug',
    description: 'Du hast deinen ersten Flugzeug-Sprung gemacht!',
    icon: '✈️',
    unlocked: hasPlaneJump,
    unlockedAt: hasPlaneJump 
        ? jumps.firstWhere((j) => j.jumpType == JumpType.PLANE).date 
        : null,
  );
  achievements.add(firstPlaneAchievement);
  
  // First Cliff Achievement
  final hasCliffJump = jumps.any((j) => j.jumpType == JumpType.CLIFF);
  final firstCliffAchievement = Achievement(
    type: AchievementType.FIRST_CLIFF,
    title: 'Erstes Mal Klippe',
    description: 'Du hast deinen ersten Klippen-Sprung gemacht!',
    icon: '⛰️',
    unlocked: hasCliffJump,
    unlockedAt: hasCliffJump 
        ? jumps.firstWhere((j) => j.jumpType == JumpType.CLIFF).date 
        : null,
  );
  achievements.add(firstCliffAchievement);
  
  return achievements;
}
