import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:wenest/models/profile.dart';
import 'package:wenest/models/agency.dart';
import 'package:wenest/models/agent.dart';
import 'package:wenest/models/landlord.dart';
import 'package:wenest/models/property.dart';
import 'package:wenest/models/property_media.dart';
import 'package:wenest/models/amenity.dart';
import 'dart:io';

class SupabaseService {
  static const String supabaseUrl = 'https://gcbpxkwwscylyjemdpcd.supabase.co';
  static const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdjYnB4a3d3c2N5bHlqZW1kcGNkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc2NTcyMzksImV4cCI6MjA2MzIzMzIzOX0.l-HRTFc3LjV3ULWRCUjrKgMfsY95voNn22pkwin0iVA';

  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
  }

  // ============ AUTHENTICATION ============
  
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    String? userType,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': name,
        'user_type': userType ?? 'user',
      },
    );
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<void> resetPasswordForEmail(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  User? getCurrentUser() {
    return client.auth.currentUser;
  }

  Stream<AuthState> authStateChanges() {
    return client.auth.onAuthStateChange;
  }

  // ============ PROFILE METHODS ============
  
  Future<Profile?> getProfile(String id) async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', id)
          .single();
      return Profile.fromJson(response);
    } catch (e) {
      debugPrint('Error getting profile: $e');
      return null;
    }
  }

  Future<String?> getUserType(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select('user_type')
          .eq('id', userId)
          .single();
      return response['user_type'] as String?;
    } catch (e) {
      debugPrint('Error getting user type: $e');
      return null;
    }
  }

  Future<void> updateUserType(String userId, String userType) async {
    await client
        .from('profiles')
        .update({'user_type': userType})
        .eq('id', userId);
  }

  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
    String? address,
    String? state,
    String? city,
    String? bio,
  }) async {
    final Map<String, dynamic> updates = {
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (fullName != null) updates['full_name'] = fullName;
    if (phoneNumber != null) updates['phone'] = phoneNumber;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (address != null) updates['address'] = address;
    if (state != null) updates['state'] = state;
    if (city != null) updates['city'] = city;
    if (bio != null) updates['bio'] = bio;

    await client.from('profiles').update(updates).eq('id', userId);
  }

  // ============ STORAGE METHODS ============
  
  /// Delete file from Supabase Storage
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await client.storage.from(bucket).remove([path]);
    } catch (e) {
      debugPrint('Error deleting file: $e');
      rethrow;
    }
  }

  // ============ PROPERTY MEDIA METHODS ============

  /// Fetches all media files for a specific property
  /// Returns a list of PropertyMedia objects sorted by display order
  Future<List<PropertyMedia>> getPropertyMedia(String propertyId) async {
    try {
      final response = await client
          .from('property_media')
          .select()
          .eq('property_id', propertyId)
          .order('is_primary', ascending: false)  // Primary images first
          .order('display_order', ascending: true);

      return response
          .map((json) => PropertyMedia.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching property media: $e');
      return [];
    }
  }

  Future<void> addPropertyMedia({
    required String propertyId,
    required String fileUrl,
    String fileType = 'image',
    int displayOrder = 0,
    bool isPrimary = false,
    String? caption,
  }) async {
    try {
      await client.from('property_media').insert({
        'property_id': propertyId,
        'file_url': fileUrl,
        'file_type': fileType,
        'display_order': displayOrder,
        'is_primary': isPrimary,
        'caption': caption,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error adding property media: $e');
      rethrow;
    }
  }

  /// Upload property media file (image or video) and save to database
  Future<void> uploadPropertyMedia({
    required String propertyId,
    required File file,
    required String mediaType, // 'image' or 'video'
    int displayOrder = 0,
  }) async {
    try {
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.path.split('.').last;
      final fileName = 'property_${propertyId}_${timestamp}_$displayOrder.$extension';
      
      // Determine bucket based on media type
      // FIXED: Use single bucket for all property media
      const bucket = 'property-uploads';

      // Upload file to Supabase Storage with subfolder based on type
      final uploadPath = mediaType == 'video' 
          ? 'videos/$propertyId/$fileName'
          : 'images/$propertyId/$fileName';
      await client.storage.from(bucket).upload(
        uploadPath,
        file,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false,
        ),
      );
      
      // Get public URL
      final fileUrl = client.storage.from(bucket).getPublicUrl(uploadPath);
      
      // Save to property_media table
      await addPropertyMedia(
        propertyId: propertyId,
        fileUrl: fileUrl,
        fileType: mediaType,
        displayOrder: displayOrder,
        isPrimary: displayOrder == 0, // First image is primary
      );
    } catch (e) {
      debugPrint('Error uploading property media: $e');
      rethrow;
    }
  }

  /// Upload file and return URL (generic method)
  Future<String> uploadFile({
    required File file,
    required String bucket,
    required String path,
  }) async {
    try {
      await client.storage.from(bucket).upload(
        path,
        file,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false,
        ),
      );
      
      return client.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploading file: $e');
      rethrow;
    }
  }

  Future<void> updatePropertyMediaPrimary(String mediaId, bool isPrimary) async {
    try {
      await client.from('property_media').update({
        'is_primary': isPrimary,
      }).eq('id', mediaId);
    } catch (e) {
      debugPrint('Error updating property media: $e');
      rethrow;
    }
  }

  Future<void> deletePropertyMedia(String mediaId) async {
    try {
      await client.from('property_media').delete().eq('id', mediaId);
    } catch (e) {
      debugPrint('Error deleting property media: $e');
      rethrow;
    }
  }

  // ============ PROPERTY METHODS ============
  
  Future<Property?> getPropertyById(String id) async {
    try {
      final response = await client
          .from('properties')
          .select()
          .eq('id', id)
          .single();
      
      // Increment views count
      await incrementPropertyViews(id);
      
      final property = Property.fromJson(response);
      
      // Load media - now returns List<PropertyMedia> directly
      final mediaList = await getPropertyMedia(property.id);
      
      // Get primary image
      final primaryMedia = mediaList.where((m) => m.isPrimary).firstOrNull;
      final primaryImageUrl = primaryMedia?.fileUrl ?? 
                             (mediaList.isNotEmpty ? mediaList.first.fileUrl : null);
      
      return property.copyWith(
        media: mediaList,
        primaryImageUrl: primaryImageUrl,
      );
    } catch (e) {
      debugPrint('Error getting property: $e');
      return null;
    }
  }

  Future<void> incrementPropertyViews(String propertyId) async {
    try {
      await client.rpc('increment_property_views', params: {'property_id': propertyId});
    } catch (e) {
      debugPrint('Error incrementing views: $e');
    }
  }

  // ============ AGENCY METHODS ============
  
  Future<List<Agency>> getAgencies({bool? verified, int limit = 50}) async {
    try {
      dynamic query = client.from('agency').select();
      
      if (verified != null) {
        query = query.eq('verified', verified);
      }
      
      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      
      return (response as List).map((data) => Agency.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error getting agencies: $e');
      return [];
    }
  }

  Future<Agency?> getAgencyById(String id) async {
    try {
      final response = await client
          .from('agency')
          .select()
          .eq('id', id)
          .single();
      return Agency.fromJson(response);
    } catch (e) {
      debugPrint('Error getting agency: $e');
      return null;
    }
  }

  Future<Agency?> getAgencyByProfileId(String profileId) async {
    try {
      final response = await client
          .from('agency')
          .select()
          .eq('profile_id', profileId)
          .single();
      return Agency.fromJson(response);
    } catch (e) {
      debugPrint('Error getting agency by profile: $e');
      return null;
    }
  }

  Future<String> createAgency({
    required String profileId,
    required String name,
    required String registrationNumber,
    String? description,
    String? contactEmail,
    String? contactPhone,
    String? address,
    String? state,
    String? city,
    String? website,
  }) async {
    try {
      final response = await client.from('agency').insert({
        'profile_id': profileId,
        'name': name,
        'registration_number': registrationNumber,
        'description': description,
        'contact_email': contactEmail,
        'contact_phone': contactPhone,
        'address': address,
        'state': state,
        'city': city,
        'website': website,
        'verified': false,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();
      
      await updateUserType(profileId, 'agency');
      
      return response['id'] as String;
    } catch (e) {
      debugPrint('Error creating agency: $e');
      rethrow;
    }
  }

  Future<void> updateAgency({
    required String agencyId,
    String? name,
    String? description,
    String? contactEmail,
    String? contactPhone,
    String? address,
    String? state,
    String? city,
    String? website,
    String? logoUrl,
  }) async {
    final Map<String, dynamic> updates = {
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (contactEmail != null) updates['contact_email'] = contactEmail;
    if (contactPhone != null) updates['contact_phone'] = contactPhone;
    if (address != null) updates['address'] = address;
    if (state != null) updates['state'] = state;
    if (city != null) updates['city'] = city;
    if (website != null) updates['website'] = website;
    if (logoUrl != null) updates['logo_url'] = logoUrl;

    await client.from('agency').update(updates).eq('id', agencyId);
  }

  // ============ AGENT METHODS ============
  
  Future<List<Agent>> getAgents({bool? verified, String? agencyId}) async {
    try {
      dynamic query = client.from('agents_with_agency').select();
      
      if (verified != null) {
        query = query.eq('verified', verified);
      }
      
      if (agencyId != null) {
        query = query.eq('agency_id', agencyId);
      }
      
      query = query.eq('is_active', true);
      
      final response = await query.order('created_at', ascending: false);
      return (response as List).map((data) => Agent.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error getting agents: $e');
      return [];
    }
  }

  Future<Agent?> getAgentById(String id) async {
    try {
      final response = await client
          .from('agents_with_agency')
          .select()
          .eq('id', id)
          .single();
      return Agent.fromJson(response);
    } catch (e) {
      debugPrint('Error getting agent: $e');
      return null;
    }
  }

  Future<Agent?> getAgentByProfileId(String profileId) async {
    try {
      final response = await client
          .from('agents_with_agency')
          .select()
          .eq('profile_id', profileId)
          .single();
      return Agent.fromJson(response);
    } catch (e) {
      debugPrint('Error getting agent by profile: $e');
      return null;
    }
  }

  Future<String> createAgent({
    required String profileId,
    String? agencyId,
    required String displayName,
    required String licenseNumber,
    required int yearsOfExperience,
    required List<String> specialization,
    required String bio,
    required String phone,
    required String email,
    String? whatsapp,
  }) async {
    try {
      final response = await client.from('agents').insert({
        'profile_id': profileId,
        'agency_id': agencyId,
        'display_name': displayName,
        'license_number': licenseNumber,
        'years_of_experience': yearsOfExperience,
        'specialization': specialization,
        'bio': bio,
        'phone': phone,
        'email': email,
        'whatsapp': whatsapp,
        'verified': false,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();
      
      await updateUserType(profileId, 'agent');
      
      return response['id'] as String;
    } catch (e) {
      debugPrint('Error creating agent: $e');
      rethrow;
    }
  }

  Future<void> updateAgent({
    required String agentId,
    String? agencyId,
    String? displayName,
    String? bio,
    String? phone,
    String? email,
    String? whatsapp,
    List<String>? specialization,
  }) async {
    final Map<String, dynamic> updates = {
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (agencyId != null) updates['agency_id'] = agencyId;
    if (displayName != null) updates['display_name'] = displayName;
    if (bio != null) updates['bio'] = bio;
    if (phone != null) updates['phone'] = phone;
    if (email != null) updates['email'] = email;
    if (whatsapp != null) updates['whatsapp'] = whatsapp;
    if (specialization != null) updates['specialization'] = specialization;

    await client.from('agents').update(updates).eq('id', agentId);
  }

  // ============ LANDLORD METHODS ============
  
  Future<List<Landlord>> getLandlords({bool? verified}) async {
    try {
      dynamic query = client.from('landlords').select();
      
      if (verified != null) {
        query = query.eq('verified', verified);
      }
      
      final response = await query.order('created_at', ascending: false);
      return (response as List).map((data) => Landlord.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error getting landlords: $e');
      return [];
    }
  }

  Future<Landlord?> getLandlordById(String id) async {
    try {
      final response = await client
          .from('landlords')
          .select()
          .eq('id', id)
          .single();
      return Landlord.fromJson(response);
    } catch (e) {
      debugPrint('Error getting landlord: $e');
      return null;
    }
  }

  Future<Landlord?> getLandlordByProfileId(String profileId) async {
    try {
      final response = await client
          .from('landlords')
          .select()
          .eq('profile_id', profileId)
          .single();
      return Landlord.fromJson(response);
    } catch (e) {
      debugPrint('Error getting landlord by profile: $e');
      return null;
    }
  }

  Future<String> createLandlord({
    required String profileId,
    String? companyName,
    required String email,
    required String phone,
    required String address,
    required String state,
    required String city,
  }) async {
    try {
      final response = await client.from('landlords').insert({
        'profile_id': profileId,
        'company_name': companyName,
        'email': email,
        'phone': phone,
        'address': address,
        'state': state,
        'city': city,
        'verified': false,
        'properties_count': 0,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();
      
      await updateUserType(profileId, 'landlord');
      
      return response['id'] as String;
    } catch (e) {
      debugPrint('Error creating landlord: $e');
      rethrow;
    }
  }

  // ============ ENHANCED PROPERTY METHODS ============

  Future<List<Property>> getProperties({
    String? propertyType,
    String? listingType,
    String? state,
    String? cityArea,
    double? minPrice,
    double? maxPrice,
    int? minBedrooms,
    int? maxBedrooms,
    bool? isFeatured,
    String? status = 'active',
    String? agencyId,
    String? agentId,
    String? landlordId,
    int limit = 50,
  }) async {
    try {
      dynamic query = client.from('properties').select();

      // Only show approved AND active properties to public unless filtering by owner
      if (agencyId == null && agentId == null && landlordId == null) {
        query = query.eq('is_approved', true).eq('status', 'active');
      } else {
        // For owners, show their properties regardless of approval status
        if (agentId != null) query = query.eq('agent_id', agentId);
        if (landlordId != null) query = query.eq('landlord_id', landlordId);
        if (agencyId != null) query = query.eq('agency_id', agencyId);
      }

      if (propertyType != null) query = query.eq('property_type', propertyType);
      if (listingType != null) query = query.eq('listing_type', listingType);
      if (state != null) query = query.eq('state', state);
      if (cityArea != null) query = query.eq('city_area', cityArea);
      if (minPrice != null) query = query.gte('price', minPrice);
      if (maxPrice != null) query = query.lte('price', maxPrice);
      if (minBedrooms != null) query = query.gte('bedrooms', minBedrooms);
      if (maxBedrooms != null) query = query.lte('bedrooms', maxBedrooms);
      if (isFeatured != null) query = query.eq('is_featured', isFeatured);

      // Owner filters
      if (agencyId != null) query = query.eq('agency_id', agencyId);
      if (agentId != null) query = query.eq('agent_id', agentId);
      if (landlordId != null) query = query.eq('landlord_id', landlordId);

      final response = await query
          .order('published_at', ascending: false)
          .limit(limit);

      // Convert to Property objects and load media for each
      final properties = (response as List).map((data) => Property.fromJson(data)).toList();
      
      // Load media for all properties
      final propertiesWithMedia = <Property>[];
      for (var property in properties) {
        final mediaList = await getPropertyMedia(property.id);
        
        // Get primary image
        final primaryMedia = mediaList.where((m) => m.isPrimary).firstOrNull;
        final primaryImageUrl = primaryMedia?.fileUrl ?? 
                               (mediaList.isNotEmpty ? mediaList.first.fileUrl : null);
        
        propertiesWithMedia.add(property.copyWith(
          media: mediaList,
          primaryImageUrl: primaryImageUrl,
        ));
      }

      return propertiesWithMedia;
    } catch (e) {
      debugPrint('Error getting properties: $e');
      return [];
    }
  }

  Future<List<Property>> getPropertiesWithMedia({
    String? propertyType,
    String? listingType,
    String? state,
    String? cityArea,
    double? minPrice,
    double? maxPrice,
    int? minBedrooms,
    int? maxBedrooms,
    bool? isFeatured,
    String? status = 'active',
    String? agencyId,
    String? agentId,
    String? landlordId,
    int limit = 50,
  }) async {
    // This method now just calls getProperties since it already loads media
    return getProperties(
      propertyType: propertyType,
      listingType: listingType,
      state: state,
      cityArea: cityArea,
      minPrice: minPrice,
      maxPrice: maxPrice,
      minBedrooms: minBedrooms,
      maxBedrooms: maxBedrooms,
      isFeatured: isFeatured,
      status: status,
      agencyId: agencyId,
      agentId: agentId,
      landlordId: landlordId,
      limit: limit,
    );
  }

  Future<Property?> getPropertyByIdWithMedia(String id) async {
    // This method now just calls getPropertyById since it already loads media
    return getPropertyById(id);
  }

  Future<int> getAgencyPropertyCount(String agencyId, {String? status}) async {
    try {
      final props = await getProperties(agencyId: agencyId, status: status, limit: 1000);
      return props.length;
    } catch (e) {
      debugPrint('Error getting property count: $e');
      return 0;
    }
  }

  Future<Map<String, dynamic>> getAgencyStats(String agencyId) async {
    try {
      final properties = await getProperties(agencyId: agencyId, limit: 1000);
      
      final totalProperties = properties.length;
      final activeProperties = properties.where((p) => p.status == 'active').length;
      final soldProperties = properties.where((p) => p.status == 'sold').length;
      final rentedProperties = properties.where((p) => p.status == 'rented').length;
      final totalViews = properties.fold<int>(0, (sum, p) => sum + p.viewsCount);
      final totalSaves = properties.fold<int>(0, (sum, p) => sum + p.savesCount);
      final totalInquiries = properties.fold<int>(0, (sum, p) => sum + p.inquiriesCount);
      
      return {
        'total_properties': totalProperties,
        'active_properties': activeProperties,
        'sold_properties': soldProperties,
        'rented_properties': rentedProperties,
        'total_views': totalViews,
        'total_saves': totalSaves,
        'total_inquiries': totalInquiries,
        'average_views_per_property': totalProperties > 0 ? totalViews / totalProperties : 0,
      };
    } catch (e) {
      debugPrint('Error getting agency stats: $e');
      return {};
    }
  }

  Future<String> createProperty({
    required String title,
    required String description,
    required String propertyType,
    required String listingType,
    required double price,
    required String address,
    required String cityArea,
    required String state,
    String? agencyId,
    String? agentId,
    String? landlordId,
    int? bedrooms,
    int? bathrooms,
    int? toilets,
    double? squareMeters,
    int? yearBuilt,
    String? furnishingStatus,
    int? parkingSpaces,
    String currency = 'NGN',
    bool negotiable = false,
    String country = 'Nigeria',
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await client.from('properties').insert({
        'title': title,
        'description': description,
        'property_type': propertyType,
        'listing_type': listingType,
        'price': price,
        'address': address,
        'city_area': cityArea,
        'state': state,
        'country': country,
        'currency': currency,
        'negotiable': negotiable,
        'agency_id': agencyId,
        'agent_id': agentId,
        'landlord_id': landlordId,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'toilets': toilets,
        'square_meters': squareMeters,
        'year_built': yearBuilt,
        'furnishing_status': furnishingStatus,
        'parking_spaces': parkingSpaces,
        'latitude': latitude,
        'longitude': longitude,
        'status': 'draft',
        'is_approved': false,
        'auto_publish': true,
        'review_status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();
      
      return response['id'].toString();
    } catch (e) {
      debugPrint('Error creating property: $e');
      rethrow;
    }
  }

  Future<void> updateProperty({
    required String propertyId,
    String? title,
    String? description,
    String? propertyType,
    String? listingType,
    double? price,
    String? address,
    String? cityArea,
    String? state,
    int? bedrooms,
    int? bathrooms,
    int? toilets,
    double? squareMeters,
    int? yearBuilt,
    String? furnishingStatus,
    int? parkingSpaces,
    bool? negotiable,
    String? status,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (propertyType != null) updates['property_type'] = propertyType;
      if (listingType != null) updates['listing_type'] = listingType;
      if (price != null) updates['price'] = price;
      if (address != null) updates['address'] = address;
      if (cityArea != null) updates['city_area'] = cityArea;
      if (state != null) updates['state'] = state;
      if (bedrooms != null) updates['bedrooms'] = bedrooms;
      if (bathrooms != null) updates['bathrooms'] = bathrooms;
      if (toilets != null) updates['toilets'] = toilets;
      if (squareMeters != null) updates['square_meters'] = squareMeters;
      if (yearBuilt != null) updates['year_built'] = yearBuilt;
      if (furnishingStatus != null) updates['furnishing_status'] = furnishingStatus;
      if (parkingSpaces != null) updates['parking_spaces'] = parkingSpaces;
      if (negotiable != null) updates['negotiable'] = negotiable;
      if (status != null) updates['status'] = status;

      await client.from('properties').update(updates).eq('id', propertyId);
    } catch (e) {
      debugPrint('Error updating property: $e');
      rethrow;
    }
  }

  Future<void> deleteProperty(String propertyId) async {
    try {
      await client.from('properties').delete().eq('id', propertyId);
    } catch (e) {
      debugPrint('Error deleting property: $e');
      rethrow;
    }
  }

  Future<void> publishProperty(String propertyId) async {
    try {
      await client.from('properties').update({
        'status': 'active',
        'published_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', propertyId);
    } catch (e) {
      debugPrint('Error publishing property: $e');
      rethrow;
    }
  }

  // ============ AGENT MANAGEMENT FOR AGENCIES ============

  Future<List<Agent>> getAgencyAgents(String agencyId) async {
    try {
      final response = await client
          .from('agents_with_agency')
          .select()
          .eq('agency_id', agencyId)
          .eq('is_active', true)
          .order('created_at', ascending: false);
      
      return (response as List).map((data) => Agent.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error getting agency agents: $e');
      return [];
    }
  }

  Future<void> inviteAgentToAgency(String agentId, String agencyId) async {
    try {
      await client.from('agents').update({
        'agency_id': agencyId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', agentId);
    } catch (e) {
      debugPrint('Error inviting agent: $e');
      rethrow;
    }
  }

  Future<void> removeAgentFromAgency(String agentId) async {
    try {
      await client.from('agents').update({
        'agency_id': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', agentId);
    } catch (e) {
      debugPrint('Error removing agent: $e');
      rethrow;
    }
  }

  // ============ AMENITIES METHODS ============
// Add these methods to your SupabaseService class

// Get all amenities
Future<List<Amenity>> getAllAmenities() async {
  try {
    debugPrint('DEBUG: Fetching amenities from database...');
    
    final response = await client
        .from('amenities')
        .select()
        .order('category', ascending: true)
        .order('name', ascending: true);
    
    debugPrint('DEBUG: Raw response type: ${response.runtimeType}');
    debugPrint('DEBUG: Raw response: $response');
    
    if (response is List) {
      debugPrint('DEBUG: Response is a List with ${response.length} items');
      
      final amenities = response
          .map((data) {
            try {
              debugPrint('DEBUG: Parsing amenity data: $data');
              return Amenity.fromJson(data);
            } catch (e) {
              debugPrint('DEBUG ERROR: Failed to parse amenity: $e');
              debugPrint('DEBUG ERROR DATA: $data');
              rethrow;
            }
          })
          .toList();
      
      debugPrint('DEBUG: Successfully parsed ${amenities.length} amenities');
      return amenities;
    } else {
      debugPrint('DEBUG ERROR: Response is not a List!');
      return [];
    }
  } catch (e) {
    debugPrint('DEBUG ERROR in getAllAmenities: $e');
    return [];
  }
}

// Get amenities by category
Future<List<Amenity>> getAmenitiesByCategory(String category) async {
  try {
    final response = await client
        .from('amenities')
        .select()
        .eq('category', category)
        // Removed .eq('is_active', true) - column doesn't exist in schema
        .order('name', ascending: true);
    
    return (response as List)
        .map((data) => Amenity.fromJson(data))
        .toList();
  } catch (e) {
    debugPrint('Error getting amenities by category: $e');
    return [];
  }
}

// Add amenity to property
Future<void> addPropertyAmenity({
  required String propertyId,
  required String amenityId, // Accepts String to be flexible
}) async {
  try {
    // Parse to int since database uses bigint
    final propertyIdInt = int.parse(propertyId);
    final amenityIdInt = int.parse(amenityId);
    
    await client.from('property_amenities').insert({
      'property_id': propertyIdInt,
      'amenity_id': amenityIdInt,
      'created_at': DateTime.now().toIso8601String(),
    });
  } catch (e) {
    debugPrint('Error adding property amenity: $e');
    rethrow;
  }
}

// Remove amenity from property
Future<void> removePropertyAmenity({
  required String propertyId,
  required String amenityId,
}) async {
  try {
    // Parse to int since database uses bigint
    final propertyIdInt = int.parse(propertyId);
    final amenityIdInt = int.parse(amenityId);
    
    await client
        .from('property_amenities')
        .delete()
        .eq('property_id', propertyIdInt)
        .eq('amenity_id', amenityIdInt);
  } catch (e) {
    debugPrint('Error removing property amenity: $e');
    rethrow;
  }
}

  // Get amenities for a property
  Future<List<Amenity>> getPropertyAmenities(String propertyId) async {
    try {
      // Parse to int since database uses bigint
      final propertyIdInt = int.parse(propertyId);
      
      final response = await client
          .from('property_amenities')
          .select('amenity_id, amenities(*)')
          .eq('property_id', propertyIdInt);
      
      return (response as List)
          .map((data) => Amenity.fromJson(data['amenities']))
          .toList();
    } catch (e) {
      debugPrint('Error getting property amenities: $e');
      return [];
    }
  }

  // Update property amenities (bulk update)
  Future<void> updatePropertyAmenities({
    required String propertyId,
    required List<String> amenityIds,
  }) async {
    try {
      // Parse to int since database uses bigint
      final propertyIdInt = int.parse(propertyId);
      
      // First, remove all existing amenities
      await client
          .from('property_amenities')
          .delete()
          .eq('property_id', propertyIdInt);
      
      // Then, add the new ones
      if (amenityIds.isNotEmpty) {
        final inserts = amenityIds.map((amenityId) => {
          'property_id': propertyIdInt,
          'amenity_id': int.parse(amenityId),
          'created_at': DateTime.now().toIso8601String(),
        }).toList();
        
        await client.from('property_amenities').insert(inserts);
      }
    } catch (e) {
      debugPrint('Error updating property amenities: $e');
      rethrow;
    }
  }

  // ============ ANALYTICS METHODS ============

  Future<List<Map<String, dynamic>>> getPropertyViewsAnalytics(
    String agencyId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await client
          .from('property_views')
          .select('viewed_at, property_id')
          .gte('viewed_at', startDate.toIso8601String())
          .lte('viewed_at', endDate.toIso8601String());
      
      // Group by date
      final Map<String, int> viewsByDate = {};
      for (var view in response as List) {
        final date = DateTime.parse(view['viewed_at'] as String);
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        viewsByDate[dateKey] = (viewsByDate[dateKey] ?? 0) + 1;
      }
      
      return viewsByDate.entries
          .map((e) => {'date': e.key, 'views': e.value})
          .toList();
    } catch (e) {
      debugPrint('Error getting views analytics: $e');
      return [];
    }
  }

  Future<List<Property>> getTopPerformingProperties(
    String agencyId, {
    int limit = 10,
    String sortBy = 'views', // views, saves, inquiries
  }) async {
    try {
      // Determine the sort column
      String sortColumn;
      if (sortBy == 'saves') {
        sortColumn = 'saves_count';
      } else if (sortBy == 'inquiries') {
        sortColumn = 'inquiries_count';
      } else {
        sortColumn = 'views_count';
      }
      
      // Build and execute query in one chain
      final response = await client
          .from('properties')
          .select()
          .eq('agency_id', agencyId)
          .eq('status', 'active')
          .order(sortColumn, ascending: false)
          .limit(limit);
      
      return (response as List).map((data) => Property.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error getting top properties: $e');
      return [];
    }
  }

  // ============ HELPER METHODS ============
  
  Future<bool> hasCompletedRoleRegistration(String userId, String userType) async {
    try {
      switch (userType.toLowerCase()) {
        case 'agent':
          final agent = await getAgentByProfileId(userId);
          return agent != null;
        case 'agency':
          final agency = await getAgencyByProfileId(userId);
          return agency != null;
        case 'landlord':
          final landlord = await getLandlordByProfileId(userId);
          return landlord != null;
        case 'user':
          return true;
        default:
          return false;
      }
    } catch (e) {
      debugPrint('Error checking role registration: $e');
      return false;
    }
  }

  Future<String> getDashboardRoute(String userId) async {
    try {
      final userType = await getUserType(userId);
      if (userType == null) return '/role_selection';

      final hasCompleted = await hasCompletedRoleRegistration(userId, userType);
      
      switch (userType.toLowerCase()) {
        case 'user':
          return '/user_home';
        case 'agent':
          return hasCompleted ? '/agent_dashboard' : '/agent_registration';
        case 'agency':
          return hasCompleted ? '/agency_dashboard' : '/agency_registration';
        case 'landlord':
          return hasCompleted ? '/landlord_dashboard' : '/landlord_registration';
        default:
          return '/role_selection';
      }
    } catch (e) {
      debugPrint('Error getting dashboard route: $e');
      return '/role_selection';
    }
  }
}