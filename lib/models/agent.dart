class Agent {
  final String id;
  final String agencyId;
  final String userId;
  final String? licenseNumber;
  final String? bio;
  final double? rating;
  final int? yearsOfExperience;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Agent({
    required this.id,
    required this.agencyId,
    required this.userId,
    this.licenseNumber,
    this.bio,
    this.rating,
    this.yearsOfExperience,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] as String,
      agencyId: json['agency_id'] as String,
      userId: json['user_id'] as String,
      licenseNumber: json['license_number'] as String?,
      bio: json['bio'] as String?,
      rating: json['rating'] as double?,
      yearsOfExperience: json['years_of_experience'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agency_id': agencyId,
      'user_id': userId,
      'license_number': licenseNumber,
      'bio': bio,
      'rating': rating,
      'years_of_experience': yearsOfExperience,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}