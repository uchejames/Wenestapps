class Amenity {
  final String id;
  final String name;
  final String? icon;
  final String? category;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Amenity({
    required this.id,
    required this.name,
    this.icon,
    this.category,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory Amenity.fromJson(Map<String, dynamic> json) {
    return Amenity(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      category: json['category'] as String?,
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
      'name': name,
      'icon': icon,
      'category': category,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}