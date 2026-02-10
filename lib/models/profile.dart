class Profile {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final String userType;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? bio;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Profile({
    required this.id,
    this.fullName,
    this.avatarUrl,
    this.userType = 'user',
    this.email,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.bio,
    this.isVerified = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String? ?? (throw const FormatException('Missing required field: id')),
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      userType: json['user_type'] as String? ?? 'user',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      bio: json['bio'] as String?,
      isVerified: (json['verification_status'] as String?) == 'verified',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'user_type': userType,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'bio': bio,
      'verification_status': isVerified ? 'verified' : 'unverified',
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get displayName => fullName?.trim().isNotEmpty == true ? fullName! : 'User';

  String get initials {
    final name = displayName;
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;
}