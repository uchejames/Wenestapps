// ============= property_amenity.dart =============
class PropertyAmenity {
  final String id;
  final String propertyId;
  final String amenityId;
  final DateTime createdAt;

  PropertyAmenity({
    required this.id,
    required this.propertyId,
    required this.amenityId,
    required this.createdAt,
  });

  factory PropertyAmenity.fromJson(Map<String, dynamic> json) {
    return PropertyAmenity(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      amenityId: json['amenity_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'amenity_id': amenityId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
