class Property {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final String propertyType;
  final String address;
  final String city;
  final String state;
  final String country;
  final double price;
  final int bedrooms;
  final int bathrooms;
  final double area;
  final String areaUnit;
  final String status;
  final bool isAvailable;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Property({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.propertyType,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.price,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.areaUnit,
    required this.status,
    this.isAvailable = true,
    this.isVerified = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      propertyType: json['property_type'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      country: json['country'] as String,
      price: (json['price'] as num).toDouble(),
      bedrooms: json['bedrooms'] as int,
      bathrooms: json['bathrooms'] as int,
      area: (json['area'] as num).toDouble(),
      areaUnit: json['area_unit'] as String,
      status: json['status'] as String,
      isAvailable: json['is_available'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'title': title,
      'description': description,
      'property_type': propertyType,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'price': price,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'area_unit': areaUnit,
      'status': status,
      'is_available': isAvailable,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}