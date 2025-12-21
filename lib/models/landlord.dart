class Landlord {
  final String id;
  final String userId;
  final String? companyName;
  final String? rcNumber;
  final String? taxId;
  final bool verified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Landlord({
    required this.id,
    required this.userId,
    this.companyName,
    this.rcNumber,
    this.taxId,
    this.verified = false,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory Landlord.fromJson(Map<String, dynamic> json) {
    return Landlord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      companyName: json['company_name'] as String?,
      rcNumber: json['rc_number'] as String?,
      taxId: json['tax_id'] as String?,
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
      'user_id': userId,
      'company_name': companyName,
      'rc_number': rcNumber,
      'tax_id': taxId,
      'verified': verified,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}