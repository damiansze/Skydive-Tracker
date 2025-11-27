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
  
  // 10 Jumps Achievement
  final totalJumps = jumps.length;
  final sortedJumps = jumps.toList()..sort((a, b) => a.date.compareTo(b.date));
  final tenJumpsAchievement = Achievement(
    type: AchievementType.TEN_JUMPS,
    title: '10 Sprünge',
    description: 'Du hast bereits 10 Sprünge absolviert!',
    icon: '🎯',
    unlocked: totalJumps >= 10,
    unlockedAt: totalJumps >= 10 ? sortedJumps[9].date : null,
    requirement: totalJumps < 10 
        ? 'Noch ${10 - totalJumps} Sprünge benötigt (aktuell: $totalJumps)' 
        : null,
  );
  achievements.add(tenJumpsAchievement);
  
  // 25 Jumps Achievement
  final twentyFiveJumpsAchievement = Achievement(
    type: AchievementType.TWENTY_FIVE_JUMPS,
    title: '25 Sprünge',
    description: 'Du hast bereits 25 Sprünge absolviert!',
    icon: '🏆',
    unlocked: totalJumps >= 25,
    unlockedAt: totalJumps >= 25 ? sortedJumps[24].date : null,
    requirement: totalJumps < 25 
        ? 'Noch ${25 - totalJumps} Sprünge benötigt (aktuell: $totalJumps)' 
        : null,
  );
  achievements.add(twentyFiveJumpsAchievement);
  
  // 50 Jumps Achievement
  final fiftyJumpsAchievement = Achievement(
    type: AchievementType.FIFTY_JUMPS,
    title: '50 Sprünge',
    description: 'Du hast bereits 50 Sprünge absolviert!',
    icon: '💎',
    unlocked: totalJumps >= 50,
    unlockedAt: totalJumps >= 50 ? sortedJumps[49].date : null,
    requirement: totalJumps < 50 
        ? 'Noch ${50 - totalJumps} Sprünge benötigt (aktuell: $totalJumps)' 
        : null,
  );
  achievements.add(fiftyJumpsAchievement);
  
  // 100 Jumps Achievement
  final hundredJumpsAchievement = Achievement(
    type: AchievementType.HUNDRED_JUMPS,
    title: '100 Sprünge',
    description: 'Du hast bereits 100 Sprünge absolviert!',
    icon: '👑',
    unlocked: totalJumps >= 100,
    unlockedAt: totalJumps >= 100 ? sortedJumps[99].date : null,
    requirement: totalJumps < 100 
        ? 'Noch ${100 - totalJumps} Sprünge benötigt (aktuell: $totalJumps)' 
        : null,
  );
  achievements.add(hundredJumpsAchievement);
  
  // 10 Locations Achievement
  final tenLocationsAchievement = Achievement(
    type: AchievementType.TEN_LOCATIONS,
    title: '10 Sprungplätze',
    description: 'Du hast von 10 verschiedenen Sprungplätzen gesprungen!',
    icon: '🗺️',
    unlocked: locationsCount >= 10,
    unlockedAt: locationsCount >= 10 ? jumps.last.date : null,
    requirement: locationsCount < 10 
        ? 'Noch ${10 - locationsCount} verschiedene Sprungplätze benötigt (aktuell: $locationsCount)' 
        : null,
  );
  achievements.add(tenLocationsAchievement);
  
  // First Tandem Achievement
  final hasTandemJump = jumps.any((j) => j.jumpType == JumpType.TANDEM);
  final firstTandemAchievement = Achievement(
    type: AchievementType.FIRST_TANDEM,
    title: 'Erstes Mal Tandem',
    description: 'Du hast deinen ersten Tandem-Sprung gemacht!',
    icon: '🤝',
    unlocked: hasTandemJump,
    unlockedAt: hasTandemJump 
        ? jumps.firstWhere((j) => j.jumpType == JumpType.TANDEM).date 
        : null,
    requirement: !hasTandemJump ? 'Erfasse einen Sprung mit Sprungtyp "Tandem"' : null,
  );
  achievements.add(firstTandemAchievement);
  
  // First Solo Achievement
  final hasSoloJump = jumps.any((j) => j.jumpType == JumpType.SOLO);
  final firstSoloAchievement = Achievement(
    type: AchievementType.FIRST_SOLO,
    title: 'Erstes Mal Solo',
    description: 'Du hast deinen ersten Solo-Sprung gemacht!',
    icon: '🪂',
    unlocked: hasSoloJump,
    unlockedAt: hasSoloJump 
        ? jumps.firstWhere((j) => j.jumpType == JumpType.SOLO).date 
        : null,
    requirement: !hasSoloJump ? 'Erfasse einen Sprung mit Sprungtyp "Solo"' : null,
  );
  achievements.add(firstSoloAchievement);
  
  // First Wingsuit Achievement
  final hasWingsuitJump = jumps.any((j) => j.jumpType == JumpType.WINGSUIT);
  final firstWingsuitAchievement = Achievement(
    type: AchievementType.FIRST_WINGSUIT,
    title: 'Erstes Mal Wingsuit',
    description: 'Du hast deinen ersten Wingsuit-Sprung gemacht!',
    icon: '🦅',
    unlocked: hasWingsuitJump,
    unlockedAt: hasWingsuitJump 
        ? jumps.firstWhere((j) => j.jumpType == JumpType.WINGSUIT).date 
        : null,
    requirement: !hasWingsuitJump ? 'Erfasse einen Sprung mit Sprungtyp "Wingsuit"' : null,
  );
  achievements.add(firstWingsuitAchievement);
  
  // High Altitude Achievement (4000m+)
  final highAltitudeJumps = jumps.where((j) => j.altitude >= 4000).toList();
  final highAltitudeAchievement = Achievement(
    type: AchievementType.HIGH_ALTITUDE,
    title: 'Höhenflug',
    description: 'Du hast einen Sprung von über 4000m Höhe gemacht!',
    icon: '☁️',
    unlocked: highAltitudeJumps.isNotEmpty,
    unlockedAt: highAltitudeJumps.isNotEmpty ? highAltitudeJumps.first.date : null,
    requirement: highAltitudeJumps.isEmpty 
        ? 'Erfasse einen Sprung von mindestens 4000m Höhe' 
        : null,
  );
  achievements.add(highAltitudeAchievement);
  
  // Equipment Master Achievement (used equipment in at least 5 jumps)
  final jumpsWithEquipment = jumps.where((j) => j.equipmentIds.isNotEmpty).toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  final equipmentMasterAchievement = Achievement(
    type: AchievementType.EQUIPMENT_MASTER,
    title: 'Equipment Meister',
    description: 'Du hast in mindestens 5 Sprüngen Equipment verwendet!',
    icon: '🎒',
    unlocked: jumpsWithEquipment.length >= 5,
    unlockedAt: jumpsWithEquipment.length >= 5 ? jumpsWithEquipment[4].date : null,
    requirement: jumpsWithEquipment.length < 5 
        ? 'Noch ${5 - jumpsWithEquipment.length} Sprünge mit Equipment benötigt (aktuell: ${jumpsWithEquipment.length})' 
        : null,
  );
  achievements.add(equipmentMasterAchievement);
  
  return achievements;
}
