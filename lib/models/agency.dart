// Updated agency.dart with profileId added
class Agency {
  final String id;
  final String? profileId; // Added this field
  final String name;
  final String? description;
  final String? logoUrl;
  final String? email;
  final String? phoneNumber;
  final String? address;
  final String? state;
  final String? lga;
  final bool verified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Agency({
    required this.id,
    this.profileId, // Added to constructor
    required this.name,
    this.description,
    this.logoUrl,
    this.email,
    this.phoneNumber,
    this.address,
    this.state,
    this.lga,
    this.verified = false,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  // Getters for compatibility with UI code
  String? get city => lga; // Map lga to city for compatibility
  String? get contactPhone => phoneNumber;
  String? get contactEmail => email;

  factory Agency.fromJson(Map<String, dynamic> json) {
    return Agency(
      id: json['id'] as String,
      profileId: json['profile_id'] as String?, // Added mapping
      name: json['name'] as String,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      email: json['contact_email'] as String? ?? json['email'] as String?,
      phoneNumber: json['contact_phone'] as String? ?? json['phone_number'] as String?,
      address: json['address'] as String?,
      state: json['state'] as String?,
      lga: json['city'] as String? ?? json['lga'] as String?,
      verified: json['verified'] as bool? ?? false,
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
      'profile_id': profileId, // Added to JSON
      'name': name,
      'description': description,
      'logo_url': logoUrl,
      'email': email,
      'contact_email': email,
      'phone_number': phoneNumber,
      'contact_phone': phoneNumber,
      'address': address,
      'state': state,
      'lga': lga,
      'city': lga,
      'verified': verified,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}