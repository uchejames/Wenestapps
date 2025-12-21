class PropertyMedia {
  final String id;
  final String propertyId;
  final String mediaUrl;
  final String mediaType; // image, video
  final int displayOrder;
  final DateTime createdAt;

  PropertyMedia({
    required this.id,
    required this.propertyId,
    required this.mediaUrl,
    required this.mediaType,
    this.displayOrder = 0,
    required this.createdAt,
  });

  factory PropertyMedia.fromJson(Map<String, dynamic> json) {
    return PropertyMedia(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      mediaUrl: json['media_url'] as String,
      mediaType: json['media_type'] as String,
      displayOrder: json['display_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
