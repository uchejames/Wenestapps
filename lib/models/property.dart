import 'property_media.dart';

class Property {
  final int id;
  final String? agentId;
  final String? landlordId;
  final String? agencyId;
  final String title;
  final String description;
  final String propertyType;
  final String listingType;
  final double price;
  final String currency;
  final bool negotiable;
  final String address;
  final String cityArea;
  final String state;
  final String country;
  final double? latitude;
  final double? longitude;
  final int? bedrooms;
  final int? bathrooms;
  final int? toilets;
  final double? squareMeters;
  final int? yearBuilt;
  final String? furnishingStatus;
  final int parkingSpaces;
  final String status;
  final bool isApproved;
  final bool isFeatured;
  final bool isVerified;
  final int viewsCount;
  final int savesCount;
  final int inquiriesCount;
  final String? slug;
  final String? metaTitle;
  final String? metaDescription;
  final DateTime? publishedAt;
  final DateTime? featuredUntil;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? reviewStatus;
  final DateTime? reviewSubmittedAt;
  final String? reviewNotes;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final bool autoPublish;
  
  // Media fields
  final List<PropertyMedia> media;
  final String? primaryImageUrl;

  Property({
    required this.id,
    this.agentId,
    this.landlordId,
    this.agencyId,
    required this.title,
    required this.description,
    required this.propertyType,
    required this.listingType,
    required this.price,
    this.currency = 'NGN',
    this.negotiable = false,
    required this.address,
    required this.cityArea,
    required this.state,
    this.country = 'Nigeria',
    this.latitude,
    this.longitude,
    this.bedrooms,
    this.bathrooms,
    this.toilets,
    this.squareMeters,
    this.yearBuilt,
    this.furnishingStatus,
    this.parkingSpaces = 0,
    this.status = 'draft',
    this.isApproved = false,
    this.isFeatured = false,
    this.isVerified = false,
    this.viewsCount = 0,
    this.savesCount = 0,
    this.inquiriesCount = 0,
    this.slug,
    this.metaTitle,
    this.metaDescription,
    this.publishedAt,
    this.featuredUntil,
    required this.createdAt,
    required this.updatedAt,
    this.reviewStatus,
    this.reviewSubmittedAt,
    this.reviewNotes,
    this.reviewedBy,
    this.reviewedAt,
    this.autoPublish = true,
    this.media = const [],
    this.primaryImageUrl,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as int,
      agentId: json['agent_id'] as String?,
      landlordId: json['landlord_id'] as String?,
      agencyId: json['agency_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      propertyType: json['property_type'] as String,
      listingType: json['listing_type'] as String,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'NGN',
      negotiable: json['negotiable'] as bool? ?? false,
      address: json['address'] as String,
      cityArea: json['city_area'] as String,
      state: json['state'] as String,
      country: json['country'] as String? ?? 'Nigeria',
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      bedrooms: json['bedrooms'] as int?,
      bathrooms: json['bathrooms'] as int?,
      toilets: json['toilets'] as int?,
      squareMeters: json['square_meters'] != null ? (json['square_meters'] as num).toDouble() : null,
      yearBuilt: json['year_built'] as int?,
      furnishingStatus: json['furnishing_status'] as String?,
      parkingSpaces: json['parking_spaces'] as int? ?? 0,
      status: json['status'] as String? ?? 'draft',
      isApproved: json['is_approved'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      viewsCount: json['views_count'] as int? ?? 0,
      savesCount: json['saves_count'] as int? ?? 0,
      inquiriesCount: json['inquiries_count'] as int? ?? 0,
      slug: json['slug'] as String?,
      metaTitle: json['meta_title'] as String?,
      metaDescription: json['meta_description'] as String?,
      publishedAt: json['published_at'] != null ? DateTime.parse(json['published_at'] as String) : null,
      featuredUntil: json['featured_until'] != null ? DateTime.parse(json['featured_until'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      reviewStatus: json['review_status'] as String?,
      reviewSubmittedAt: json['review_submitted_at'] != null ? DateTime.parse(json['review_submitted_at'] as String) : null,
      reviewNotes: json['review_notes'] as String?,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at'] as String) : null,
      autoPublish: json['auto_publish'] as bool? ?? true,
      media: [], // Will be loaded separately
      primaryImageUrl: null, // Will be loaded separately
    );
  }

  Property copyWith({
    List<PropertyMedia>? media,
    String? primaryImageUrl,
  }) {
    return Property(
      id: id,
      agentId: agentId,
      landlordId: landlordId,
      agencyId: agencyId,
      title: title,
      description: description,
      propertyType: propertyType,
      listingType: listingType,
      price: price,
      currency: currency,
      negotiable: negotiable,
      address: address,
      cityArea: cityArea,
      state: state,
      country: country,
      latitude: latitude,
      longitude: longitude,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      toilets: toilets,
      squareMeters: squareMeters,
      yearBuilt: yearBuilt,
      furnishingStatus: furnishingStatus,
      parkingSpaces: parkingSpaces,
      status: status,
      isApproved: isApproved,
      isFeatured: isFeatured,
      isVerified: isVerified,
      viewsCount: viewsCount,
      savesCount: savesCount,
      inquiriesCount: inquiriesCount,
      slug: slug,
      metaTitle: metaTitle,
      metaDescription: metaDescription,
      publishedAt: publishedAt,
      featuredUntil: featuredUntil,
      createdAt: createdAt,
      updatedAt: updatedAt,
      reviewStatus: reviewStatus,
      reviewSubmittedAt: reviewSubmittedAt,
      reviewNotes: reviewNotes,
      reviewedBy: reviewedBy,
      reviewedAt: reviewedAt,
      autoPublish: autoPublish,
      media: media ?? this.media,
      primaryImageUrl: primaryImageUrl ?? this.primaryImageUrl,
    );
  }

  String get locationDisplay => '$cityArea, $state';
  
  String get formattedPrice {
    final priceStr = price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '₦$priceStr';
  }

  String get listingTypeDisplay {
    switch (listingType) {
      case 'rent':
        return 'For Rent';
      case 'sale':
        return 'For Sale';
      case 'lease':
        return 'For Lease';
      case 'shortlet':
        return 'Shortlet';
      default:
        return listingType;
    }
  }

  String get propertyTypeDisplay {
    switch (propertyType) {
      case 'apartment':
        return 'Apartment';
      case 'house':
        return 'House';
      case 'condo':
        return 'Condo';
      case 'land':
        return 'Land';
      case 'commercial':
        return 'Commercial';
      case 'office':
        return 'Office';
      case 'warehouse':
        return 'Warehouse';
      default:
        return propertyType;
    }
  }
}