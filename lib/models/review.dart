class Review {
  final String id;
  final String propertyId;
  final String userId;
  final String? agencyId;
  final int rating;
  final String? comment;
  final bool isApproved;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Review({
    required this.id,
    required this.propertyId,
    required this.userId,
    this.agencyId,
    required this.rating,
    this.comment,
    this.isApproved = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      userId: json['user_id'] as String,
      agencyId: json['agency_id'] as String?,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      isApproved: json['is_approved'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'user_id': userId,
      'agency_id': agencyId,
      'rating': rating,
      'comment': comment,
      'is_approved': isApproved,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}