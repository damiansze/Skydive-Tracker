class Profile {
  final String id;
  final String name;
  final String? licenseNumber;
  final String? licenseType;
  final String? profilePictureUrl;
  final int totalJumps;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile({
    required this.id,
    required this.name,
    this.licenseNumber,
    this.licenseType,
    this.profilePictureUrl,
    this.totalJumps = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'license_number': licenseNumber,
      'license_type': licenseType,
      'profile_picture_url': profilePictureUrl,
      'total_jumps': totalJumps,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      name: map['name'] as String,
      licenseNumber: map['license_number'] as String?,
      licenseType: map['license_type'] as String?,
      profilePictureUrl: map['profile_picture_url'] as String?,
      totalJumps: map['total_jumps'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Profile copyWith({
    String? id,
    String? name,
    String? licenseNumber,
    String? licenseType,
    String? profilePictureUrl,
    int? totalJumps,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseType: licenseType ?? this.licenseType,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      totalJumps: totalJumps ?? this.totalJumps,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
