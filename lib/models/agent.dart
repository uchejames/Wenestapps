class Agent {
  final String id;
  final String profileId;
  final String? agencyId;
  final String? displayName;
  final String? licenseNumber;
  final bool verified;
  final int? yearsOfExperience;
  final List<String>? specialization;
  final String? bio;
  final double? rating;
  final int? reviewsCount;
  final int? propertiesCount;
  final String? phone;
  final String? email;
  final String? whatsapp;
  final double? commissionRate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Additional fields from view
  final String? agencyName;
  final String? agencyLogoUrl;
  final bool? agencyVerified;
  final String? fullName;
  final String? avatarUrl;

  Agent({
    required this.id,
    required this.profileId,
    this.agencyId,
    this.displayName,
    this.licenseNumber,
    this.verified = false,
    this.yearsOfExperience,
    this.specialization,
    this.bio,
    this.rating,
    this.reviewsCount,
    this.propertiesCount,
    this.phone,
    this.email,
    this.whatsapp,
    this.commissionRate,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.agencyName,
    this.agencyLogoUrl,
    this.agencyVerified,
    this.fullName,
    this.avatarUrl,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      agencyId: json['agency_id'] as String?,
      displayName: json['display_name'] as String?,
      licenseNumber: json['license_number'] as String?,
      verified: json['verified'] as bool? ?? false,
      yearsOfExperience: json['years_of_experience'] as int?,
      specialization: json['specialization'] != null
          ? List<String>.from(json['specialization'])
          : null,
      bio: json['bio'] as String?,
      rating: json['rating'] != null 
          ? (json['rating'] as num).toDouble() 
          : null,
      reviewsCount: json['reviews_count'] as int?,
      propertiesCount: json['properties_count'] as int?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      whatsapp: json['whatsapp'] as String?,
      commissionRate: json['commission_rate'] != null
          ? (json['commission_rate'] as num).toDouble()
          : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      agencyName: json['agency_name'] as String?,
      agencyLogoUrl: json['agency_logo_url'] as String?,
      agencyVerified: json['agency_verified'] as bool?,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'agency_id': agencyId,
      'display_name': displayName,
      'license_number': licenseNumber,
      'verified': verified,
      'years_of_experience': yearsOfExperience,
      'specialization': specialization,
      'bio': bio,
      'rating': rating,
      'reviews_count': reviewsCount,
      'properties_count': propertiesCount,
      'phone': phone,
      'email': email,
      'whatsapp': whatsapp,
      'commission_rate': commissionRate,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isAffiliated => agencyId != null;

  String get displayTitle {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    return fullName ?? 'Agent';
  }
}