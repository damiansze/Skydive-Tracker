class Jump {
  final String id;
  final DateTime date;
  final String location;
  final double? latitude;
  final double? longitude;
  final int altitude;
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
      'checklist_completed': checklistCompleted ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Jump.fromMap(Map<String, dynamic> map) {
    return Jump(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      location: map['location'] as String,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      altitude: map['altitude'] as int,
      checklistCompleted: (map['checklist_completed'] as int) == 1,
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
      equipmentIds: equipmentIds ?? this.equipmentIds,
      checklistCompleted: checklistCompleted ?? this.checklistCompleted,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
