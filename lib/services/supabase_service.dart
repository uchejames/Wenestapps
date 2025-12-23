import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wenest/models/profile.dart';
import 'package:wenest/models/agency.dart';
import 'package:wenest/models/agent.dart';
import 'package:wenest/models/landlord.dart';
import 'package:wenest/models/property.dart';

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
      print('Error getting profile: $e');
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
      print('Error getting user type: $e');
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

  // ============ PROPERTY METHODS ============
  
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
    int limit = 50,
  }) async {
    try {
      var query = client
          .from('properties')
          .select()
          .eq('is_approved', true);
      
      if (status != null) query = query.eq('status', status);
      if (propertyType != null) query = query.eq('property_type', propertyType);
      if (listingType != null) query = query.eq('listing_type', listingType);
      if (state != null) query = query.eq('state', state);
      if (cityArea != null) query = query.eq('city_area', cityArea);
      if (minPrice != null) query = query.gte('price', minPrice);
      if (maxPrice != null) query = query.lte('price', maxPrice);
      if (minBedrooms != null) query = query.gte('bedrooms', minBedrooms);
      if (maxBedrooms != null) query = query.lte('bedrooms', maxBedrooms);
      if (isFeatured != null) query = query.eq('is_featured', isFeatured);
      
      final response = await query
          .order('published_at', ascending: false)
          .limit(limit);
      
      return (response as List).map((data) => Property.fromJson(data)).toList();
    } catch (e) {
      print('Error getting properties: $e');
      return [];
    }
  }

  Future<Property?> getPropertyById(String id) async {
    try {
      final response = await client
          .from('properties')
          .select()
          .eq('id', id)
          .single();
      
      // Increment views count
      await incrementPropertyViews(id);
      
      return Property.fromJson(response);
    } catch (e) {
      print('Error getting property: $e');
      return null;
    }
  }

  Future<void> incrementPropertyViews(String propertyId) async {
    try {
      await client.rpc('increment_property_views', params: {'property_id': propertyId});
    } catch (e) {
      print('Error incrementing views: $e');
    }
  }

  // ============ AGENCY METHODS ============
  
  Future<List<Agency>> getAgencies({bool? verified, int limit = 50}) async {
    try {
      var query = client.from('agency').select();
      
      if (verified != null) {
        query = query.eq('verified', verified);
      }
      
      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      
      return (response as List).map((data) => Agency.fromJson(data)).toList();
    } catch (e) {
      print('Error getting agencies: $e');
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
      print('Error getting agency: $e');
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
      print('Error getting agency by profile: $e');
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
      print('Error creating agency: $e');
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
      var query = client.from('agents_with_agency').select();
      
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
      print('Error getting agents: $e');
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
      print('Error getting agent: $e');
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
      print('Error getting agent by profile: $e');
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
      print('Error creating agent: $e');
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
      var query = client.from('landlords').select();
      
      if (verified != null) {
        query = query.eq('verified', verified);
      }
      
      final response = await query.order('created_at', ascending: false);
      return (response as List).map((data) => Landlord.fromJson(data)).toList();
    } catch (e) {
      print('Error getting landlords: $e');
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
      print('Error getting landlord: $e');
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
      print('Error getting landlord by profile: $e');
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
      print('Error creating landlord: $e');
      rethrow;
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
      print('Error checking role registration: $e');
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
      print('Error getting dashboard route: $e');
      return '/role_selection';
    }
  }
}