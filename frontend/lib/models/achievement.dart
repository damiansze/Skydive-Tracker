enum AchievementType {
  FIRST_JUMP,
  FIVE_LOCATIONS,
  FIRST_HELICOPTER,
  FIRST_PLANE,
  FIRST_CLIFF,
  TEN_JUMPS,
  TWENTY_FIVE_JUMPS,
  FIFTY_JUMPS,
  HUNDRED_JUMPS,
  TEN_LOCATIONS,
  FIRST_TANDEM,
  FIRST_SOLO,
  FIRST_WINGSUIT,
  HIGH_ALTITUDE,
  EQUIPMENT_MASTER,
}

class Achievement {
  final AchievementType type;
  final String title;
  final String description;
  final String icon;
  final bool unlocked;
  final DateTime? unlockedAt;
  final String? requirement; // What needs to be done to unlock

  Achievement({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    this.unlocked = false,
    this.unlockedAt,
    this.requirement,
  });

  Achievement copyWith({
    AchievementType? type,
    String? title,
    String? description,
    String? icon,
    bool? unlocked,
    DateTime? unlockedAt,
    String? requirement,
  }) {
    return Achievement(
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      unlocked: unlocked ?? this.unlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      requirement: requirement ?? this.requirement,
    );
  }
}
