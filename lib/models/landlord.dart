class Landlord {
  final String id;
  final String profileId;
  final String? companyName;
  final String? email;
  final String? phone;
  final bool verified;
  final String? address;
  final String? state;
  final String? city;
  final int? propertiesCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Landlord({
    required this.id,
    required this.profileId,
    this.companyName,
    this.email,
    this.phone,
    this.verified = false,
    this.address,
    this.state,
    this.city,
    this.propertiesCount,
    required this.createdAt,
    this.updatedAt,
  });

  factory Landlord.fromJson(Map<String, dynamic> json) {
    return Landlord(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      companyName: json['company_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      verified: json['verified'] as bool? ?? false,
      address: json['address'] as String?,
      state: json['state'] as String?,
      city: json['city'] as String?,
      propertiesCount: json['properties_count'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'company_name': companyName,
      'email': email,
      'phone': phone,
      'verified': verified,
      'address': address,
      'state': state,
      'city': city,
      'properties_count': propertiesCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}