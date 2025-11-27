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
    requirement: jumps.isEmpty ? 'Erfasse deinen ersten Sprung' : null,
  );
  achievements.add(firstJumpAchievement);
  
  // Five Locations Achievement
  final uniqueLocations = jumps.map((j) => j.location).toSet();
  final locationsCount = uniqueLocations.length;
  final fiveLocationsAchievement = Achievement(
    type: AchievementType.FIVE_LOCATIONS,
    title: '5 Sprungplätze',
    description: 'Du hast von 5 verschiedenen Sprungplätzen gesprungen!',
    icon: '🌍',
    unlocked: locationsCount >= 5,
    unlockedAt: locationsCount >= 5 ? jumps.last.date : null,
    requirement: locationsCount < 5 
        ? 'Noch ${5 - locationsCount} verschiedene Sprungplätze benötigt (aktuell: $locationsCount)' 
        : null,
  );
  achievements.add(fiveLocationsAchievement);
  
  // First Helicopter Achievement
  final hasHelicopterJump = jumps.any((j) => j.jumpMethod == JumpMethod.HELICOPTER);
  final firstHelicopterAchievement = Achievement(
    type: AchievementType.FIRST_HELICOPTER,
    title: 'Erstes Mal Helikopter',
    description: 'Du hast deinen ersten Helikopter-Sprung gemacht!',
    icon: '🚁',
    unlocked: hasHelicopterJump,
    unlockedAt: hasHelicopterJump 
        ? jumps.firstWhere((j) => j.jumpMethod == JumpMethod.HELICOPTER).date 
        : null,
    requirement: !hasHelicopterJump ? 'Erfasse einen Sprung mit Sprungmethode "Helikopter"' : null,
  );
  achievements.add(firstHelicopterAchievement);
  
  // First Plane Achievement
  final hasPlaneJump = jumps.any((j) => j.jumpMethod == JumpMethod.PLANE);
  final firstPlaneAchievement = Achievement(
    type: AchievementType.FIRST_PLANE,
    title: 'Erstes Mal Flugzeug',
    description: 'Du hast deinen ersten Flugzeug-Sprung gemacht!',
    icon: '✈️',
    unlocked: hasPlaneJump,
    unlockedAt: hasPlaneJump 
        ? jumps.firstWhere((j) => j.jumpMethod == JumpMethod.PLANE).date 
        : null,
    requirement: !hasPlaneJump ? 'Erfasse einen Sprung mit Sprungmethode "Flugzeug"' : null,
  );
  achievements.add(firstPlaneAchievement);
  
  // First BASE Achievement
  final hasBaseJump = jumps.any((j) => j.jumpMethod == JumpMethod.BASE);
  final firstBaseAchievement = Achievement(
    type: AchievementType.FIRST_CLIFF,
    title: 'Erstes Mal BASE Jump',
    description: 'Du hast deinen ersten BASE Jump gemacht!',
    icon: '⛰️',
    unlocked: hasBaseJump,
    unlockedAt: hasBaseJump 
        ? jumps.firstWhere((j) => j.jumpMethod == JumpMethod.BASE).date 
        : null,
    requirement: !hasBaseJump ? 'Erfasse einen Sprung mit Sprungmethode "BASE Jump"' : null,
  );
  achievements.add(firstBaseAchievement);
  
  return achievements;
}
