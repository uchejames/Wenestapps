class PropertyMedia {
  final String id;
  final String propertyId;
  final String fileUrl;  // Database column is 'file_url' not 'media_url'
  final String fileType;  // Database column is 'file_type' not 'media_type'
  final String? caption;  // Optional caption field from database
  final int displayOrder;
  final bool isPrimary;  // Important: marks the primary image
  final DateTime createdAt;

  PropertyMedia({
    required this.id,
    required this.propertyId,
    required this.fileUrl,
    required this.fileType,
    this.caption,
    this.displayOrder = 0,
    this.isPrimary = false,
    required this.createdAt,
  });

  factory PropertyMedia.fromJson(Map<String, dynamic> json) {
    return PropertyMedia(
      id: json['id'] as String,
      propertyId: json['property_id'].toString(),  // Convert bigint to String
      fileUrl: json['file_url'] as String,
      fileType: json['file_type'] as String? ?? 'image',
      caption: json['caption'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      isPrimary: json['is_primary'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'file_url': fileUrl,
      'file_type': fileType,
      'caption': caption,
      'display_order': displayOrder,
      'is_primary': isPrimary,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PropertyMedia copyWith({
    String? id,
    String? propertyId,
    String? fileUrl,
    String? fileType,
    String? caption,
    int? displayOrder,
    bool? isPrimary,
    DateTime? createdAt,
  }) {
    return PropertyMedia(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      caption: caption ?? this.caption,
      displayOrder: displayOrder ?? this.displayOrder,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper getters
  bool get isImage => fileType == 'image';
  bool get isVideo => fileType == 'video';
  bool get isDocument => fileType == 'document';
  bool get isFloorPlan => fileType == 'floor_plan';
}