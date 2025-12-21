// ============= property_view.dart =============
class PropertyView {
  final String id;
  final String propertyId;
  final String? userId;
  final DateTime viewedAt;

  PropertyView({
    required this.id,
    required this.propertyId,
    this.userId,
    required this.viewedAt,
  });

  factory PropertyView.fromJson(Map<String, dynamic> json) {
    return PropertyView(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      userId: json['user_id'] as String?,
      viewedAt: DateTime.parse(json['viewed_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'user_id': userId,
      'viewed_at': viewedAt.toIso8601String(),
    };
  }
}
