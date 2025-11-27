class Equipment {
  final String id;
  final String name;
  final EquipmentType type;
  final String? manufacturer;
  final String? model;
  final String? serialNumber;
  final DateTime? purchaseDate;
  final String? notes;
  final DateTime? createdAt;

  Equipment({
    required this.id,
    required this.name,
    required this.type,
    this.manufacturer,
    this.model,
    this.serialNumber,
    this.purchaseDate,
    this.notes,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'manufacturer': manufacturer,
      'model': model,
      'serial_number': serialNumber,
      'purchase_date': purchaseDate?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Equipment.fromMap(Map<String, dynamic> map) {
    return Equipment(
      id: map['id'] as String,
      name: map['name'] as String,
      type: EquipmentType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => EquipmentType.OTHER,
      ),
      manufacturer: map['manufacturer'] as String?,
      model: map['model'] as String?,
      serialNumber: map['serial_number'] as String?,
      purchaseDate: map['purchase_date'] != null
          ? DateTime.parse(map['purchase_date'] as String)
          : null,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Equipment copyWith({
    String? id,
    String? name,
    EquipmentType? type,
    String? manufacturer,
    String? model,
    String? serialNumber,
    DateTime? purchaseDate,
    String? notes,
    DateTime? createdAt,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum EquipmentType {
  PARACHUTE,
  HARNESS,
  RESERVE,
  ALTIMETER,
  HELMET,
  GOGGLES,
  OTHER,
}

extension EquipmentTypeExtension on EquipmentType {
  String get displayName {
    switch (this) {
      case EquipmentType.PARACHUTE:
        return 'Fallschirm';
      case EquipmentType.HARNESS:
        return 'Gurtzeug';
      case EquipmentType.RESERVE:
        return 'Reserve';
      case EquipmentType.ALTIMETER:
        return 'Höhenmesser';
      case EquipmentType.HELMET:
        return 'Helm';
      case EquipmentType.GOGGLES:
        return 'Brille';
      case EquipmentType.OTHER:
        return 'Sonstiges';
    }
  }
}
