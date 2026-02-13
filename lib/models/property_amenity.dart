// ============= property_amenity.dart =============
class PropertyAmenity {
  final int id; // Changed from String to int
  final int propertyId; // Changed from String to int
  final int amenityId; // Changed from String to int
  final DateTime createdAt;

  PropertyAmenity({
    required this.id,
    required this.propertyId,
    required this.amenityId,
    required this.createdAt,
  });

  factory PropertyAmenity.fromJson(Map<String, dynamic> json) {
    return PropertyAmenity(
      id: json['id'] as int,
      propertyId: json['property_id'] as int,
      amenityId: json['amenity_id'] as int,
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