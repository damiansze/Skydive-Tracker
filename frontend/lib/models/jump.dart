enum JumpType {
  TANDEM,
  SOLO,
  PLANE,
  HELICOPTER,
  CLIFF,
}

extension JumpTypeExtension on JumpType {
  String get displayName {
    switch (this) {
      case JumpType.TANDEM:
        return 'Tandem';
      case JumpType.SOLO:
        return 'Solo';
      case JumpType.PLANE:
        return 'Flugzeug';
      case JumpType.HELICOPTER:
        return 'Helikopter';
      case JumpType.CLIFF:
        return 'Klippe';
    }
  }
}

class Jump {
  final String id;
  final DateTime date;
  final String location;
  final double? latitude;
  final double? longitude;
  final int altitude;
  final JumpType? jumpType;
  final List<String> equipmentIds;
  final bool checklistCompleted;
  final String? notes;
  final DateTime createdAt;

  Jump({
    required this.id,
    required this.date,
    required this.location,
    this.latitude,
    this.longitude,
    required this.altitude,
    this.jumpType,
    this.equipmentIds = const [],
    this.checklistCompleted = false,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'jump_type': jumpType?.toString().split('.').last.toLowerCase(),
      'checklist_completed': checklistCompleted ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Jump.fromMap(Map<String, dynamic> map) {
    // Handle both int and bool for checklist_completed
    bool checklistCompleted = false;
    if (map['checklist_completed'] != null) {
      if (map['checklist_completed'] is bool) {
        checklistCompleted = map['checklist_completed'] as bool;
      } else {
        checklistCompleted = (map['checklist_completed'] as int) == 1;
      }
    }
    
    // Handle equipment_ids from backend
    List<String> equipmentIds = [];
    if (map['equipment_ids'] != null) {
      equipmentIds = List<String>.from(map['equipment_ids'] as List);
    }
    
    // Handle jump_type from backend
    JumpType? jumpType;
    if (map['jump_type'] != null) {
      final typeString = map['jump_type'].toString().toLowerCase();
      try {
        jumpType = JumpType.values.firstWhere(
          (e) => e.toString().split('.').last.toLowerCase() == typeString,
        );
      } catch (e) {
        jumpType = null;
      }
    }
    
    return Jump(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      location: map['location'] as String,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      altitude: map['altitude'] as int,
      jumpType: jumpType,
      equipmentIds: equipmentIds,
      checklistCompleted: checklistCompleted,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Jump copyWith({
    String? id,
    DateTime? date,
    String? location,
    double? latitude,
    double? longitude,
    int? altitude,
    JumpType? jumpType,
    List<String>? equipmentIds,
    bool? checklistCompleted,
    String? notes,
    DateTime? createdAt,
  }) {
    return Jump(
      id: id ?? this.id,
      date: date ?? this.date,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      jumpType: jumpType ?? this.jumpType,
      equipmentIds: equipmentIds ?? this.equipmentIds,
      checklistCompleted: checklistCompleted ?? this.checklistCompleted,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
