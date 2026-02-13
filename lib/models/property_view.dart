// ============= property_view.dart (CORRECTED) =============
// Updated to match your actual database schema
class PropertyView {
  final String id;
  final int propertyId;  // Changed to int to match bigint in database
  final String? viewerId;  // CORRECTED: Changed from userId to viewerId
  final String? ipAddress;
  final String? userAgent;
  final DateTime viewedAt;

  PropertyView({
    required this.id,
    required this.propertyId,
    this.viewerId,  // CORRECTED
    this.ipAddress,
    this.userAgent,
    required this.viewedAt,
  });

  factory PropertyView.fromJson(Map<String, dynamic> json) {
    return PropertyView(
      id: json['id'] as String,
      propertyId: json['property_id'] is int 
          ? json['property_id'] as int
          : int.parse(json['property_id'].toString()),
      viewerId: json['viewer_id'] as String?,  // CORRECTED
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      viewedAt: DateTime.parse(json['viewed_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'viewer_id': viewerId,  // CORRECTED
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'viewed_at': viewedAt.toIso8601String(),
    };
  }

  PropertyView copyWith({
    String? id,
    int? propertyId,
    String? viewerId,
    String? ipAddress,
    String? userAgent,
    DateTime? viewedAt,
  }) {
    return PropertyView(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      viewerId: viewerId ?? this.viewerId,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      viewedAt: viewedAt ?? this.viewedAt,
    );
  }
}