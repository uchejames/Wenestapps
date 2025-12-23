class Profile {
  final String id;
  final String? fullName;
  final String? email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String userType; // tenant, landlord, agent, agency
  final bool isVerified;
  final String? address;
  final String? city;
  final String? state;
  final String? bio;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Profile({
    required this.id,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.avatarUrl,
    required this.userType,
    this.isVerified = false,
    this.address,
    this.city,
    this.state,
    this.bio,
    required this.createdAt,
    this.updatedAt,
  });

  // Getter for compatibility with UI code
  String? get phone => phoneNumber;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phone'] as String? ?? json['phone_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      userType: json['user_type'] as String? ?? 'tenant',
      isVerified: json['is_verified'] as bool? ?? false,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      bio: json['bio'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phoneNumber,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'user_type': userType,
      'is_verified': isVerified,
      'address': address,
      'city': city,
      'state': state,
      'bio': bio,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}