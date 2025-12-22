import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wenest/models/profile.dart';
import 'package:wenest/models/agency.dart';
import 'package:wenest/models/agent.dart';
import 'package:wenest/models/landlord.dart';
import 'package:wenest/models/property.dart';
import 'package:wenest/models/property_media.dart';
import 'package:wenest/models/amenity.dart';
import 'package:wenest/models/property_amenity.dart';
import 'package:wenest/models/review.dart';
import 'package:wenest/models/favorite.dart';
import 'package:wenest/models/conversation.dart';
import 'package:wenest/models/message.dart';
import 'package:wenest/models/notification.dart' as app_notification;
import 'package:wenest/models/transaction.dart';
import 'package:wenest/models/subscription.dart';
import 'package:wenest/models/property_view.dart';
import 'package:wenest/models/report.dart';
import 'package:wenest/models/support_ticket.dart';
import 'package:wenest/models/saved_search.dart';
import 'package:wenest/utils/constants.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://gcbpxkwwscylyjemdpcd.supabase.co';
  static const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdjYnB4a3d3c2N5bHlqZW1kcGNkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc2NTcyMzksImV4cCI6MjA2MzIzMzIzOX0.l-HRTFc3LjV3ULWRCUjrKgMfsY95voNn22pkwin0iVA';

  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
  }

  /// Sign up a new user
  /// The profile is automatically created via database trigger
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
    
    // Profile is automatically created by the database trigger
    // No need to manually insert into profiles table
    
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<void> resetPasswordForEmail(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  Future<void> updatePassword(String newPassword) async {
    await client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // User methods
  User? getCurrentUser() {
    return client.auth.currentUser;
  }

  Stream<AuthState> authStateChanges() {
    return client.auth.onAuthStateChange;
  }

  // Get user type from profile
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

  // Update user type
  Future<void> updateUserType(String userId, String userType) async {
    await client
        .from('profiles')
        .update({'user_type': userType})
        .eq('id', userId);
  }

  // Profile methods
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

  Future<List<Profile>> getAllProfiles() async {
    final response = await client
        .from('profiles')
        .select()
        .order('created_at', ascending: false);
    return response.map((data) => Profile.fromJson(data)).toList();
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
    if (phoneNumber != null) updates['phone_number'] = phoneNumber;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (address != null) updates['address'] = address;
    if (state != null) updates['state'] = state;
    if (city != null) updates['city'] = city;
    if (bio != null) updates['bio'] = bio;

    await client
        .from('profiles')
        .update(updates)
        .eq('id', userId);
  }

  // Agency methods
  Future<List<Agency>> getAgencies() async {
    final response = await client
        .from('agencies')
        .select()
        .eq('verified', true)
        .order('created_at', ascending: false);
    return response.map((data) => Agency.fromJson(data)).toList();
  }

  Future<Agency?> getAgencyById(String id) async {
    try {
      final response = await client
          .from('agencies')
          .select()
          .eq('id', id)
          .single();
      return Agency.fromJson(response);
    } catch (e) {
      print('Error getting agency: $e');
      return null;
    }
  }

  // Agent methods
  Future<List<Agent>> getAgents() async {
    final response = await client
        .from('agents')
        .select()
        .eq('verified', true)
        .eq('is_active', true)
        .order('created_at', ascending: false);
    return response.map((data) => Agent.fromJson(data)).toList();
  }

  Future<Agent?> getAgentById(String id) async {
    try {
      final response = await client
          .from('agents')
          .select()
          .eq('id', id)
          .single();
      return Agent.fromJson(response);
    } catch (e) {
      print('Error getting agent: $e');
      return null;
    }
  }

  // Landlord methods
  Future<List<Landlord>> getLandlords() async {
    final response = await client
        .from('landlords')
        .select()
        .eq('verified', true)
        .order('created_at', ascending: false);
    return response.map((data) => Landlord.fromJson(data)).toList();
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

  // Property methods
  Future<List<Property>> getProperties({
    String? location,
    String? propertyType,
    num? minPrice,
    num? maxPrice,
    String? state,
    String? lga,
  }) async {
    var query = client
        .from('properties')
        .select()
        .eq('is_approved', true)
        .eq('status', 'active');

    if (location != null) {
      query = query.ilike('location', '%$location%');
    }

    if (propertyType != null) {
      query = query.eq('property_type', propertyType);
    }

    if (minPrice != null) {
      query = query.gte('price', minPrice);
    }

    if (maxPrice != null) {
      query = query.lte('price', maxPrice);
    }

    if (state != null) {
      query = query.eq('state', state);
    }

    if (lga != null) {
      query = query.eq('lga', lga);
    }

    final response = await query.order('created_at', ascending: false);
    return response.map((data) => Property.fromJson(data)).toList();
  }

  Future<Property?> getPropertyById(String id) async {
    try {
      final response = await client
          .from('properties')
          .select()
          .eq('id', id)
          .eq('is_approved', true)
          .eq('status', 'active')
          .single();
      return Property.fromJson(response);
    } catch (e) {
      print('Error getting property: $e');
      return null;
    }
  }

  // Property Media methods
  Future<List<PropertyMedia>> getPropertyMedia(String propertyId) async {
    final response = await client
        .from('property_media')
        .select()
        .eq('property_id', propertyId)
        .order('display_order', ascending: true);
    return response.map((data) => PropertyMedia.fromJson(data)).toList();
  }

  // Amenity methods
  Future<List<Amenity>> getAmenities() async {
    final response = await client
        .from('amenities_master')
        .select()
        .order('name', ascending: true);
    return response.map((data) => Amenity.fromJson(data)).toList();
  }

  // Property Amenity methods
  Future<List<PropertyAmenity>> getPropertyAmenities(String propertyId) async {
    final response = await client
        .from('property_amenities')
        .select()
        .eq('property_id', propertyId);
    return response.map((data) => PropertyAmenity.fromJson(data)).toList();
  }

  // Review methods
  Future<List<Review>> getPropertyReviews(String propertyId) async {
    final response = await client
        .from('reviews')
        .select()
        .eq('property_id', propertyId)
        .order('created_at', ascending: false);
    return response.map((data) => Review.fromJson(data)).toList();
  }

  // Favorite methods
  Future<List<Favorite>> getUserFavorites(String userId) async {
    final response = await client
        .from('favorites')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return response.map((data) => Favorite.fromJson(data)).toList();
  }

  Future<void> addFavorite({
    required String userId,
    required String propertyId,
  }) async {
    await client.from('favorites').insert({
      'user_id': userId,
      'property_id': propertyId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeFavorite({
    required String userId,
    required String propertyId,
  }) async {
    await client
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('property_id', propertyId);
  }

  // Conversation methods
  Future<List<Conversation>> getUserConversations(String userId) async {
    final response = await client
        .from('conversations')
        .select()
        .or('initiator_id.eq.$userId,receiver_id.eq.$userId')
        .order('updated_at', ascending: false);
    return response.map((data) => Conversation.fromJson(data)).toList();
  }

  // Message methods
  Future<List<Message>> getConversationMessages(String conversationId) async {
    final response = await client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
    return response.map((data) => Message.fromJson(data)).toList();
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    await client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Notification methods
  Future<List<app_notification.Notification>> getUserNotifications(String userId) async {
    final response = await client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return response.map((data) => app_notification.Notification.fromJson(data)).toList();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  // Transaction methods
  Future<List<Transaction>> getUserTransactions(String userId) async {
    final response = await client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return response.map((data) => Transaction.fromJson(data)).toList();
  }

  // Subscription methods
  Future<List<Subscription>> getAgencySubscriptions(String agencyId) async {
    final response = await client
        .from('subscriptions')
        .select()
        .eq('agency_id', agencyId)
        .order('created_at', ascending: false);
    return response.map((data) => Subscription.fromJson(data)).toList();
  }

  // Property View methods
  Future<List<PropertyView>> getPropertyViews(String propertyId) async {
    final response = await client
        .from('property_views')
        .select()
        .eq('property_id', propertyId)
        .order('viewed_at', ascending: false);
    return response.map((data) => PropertyView.fromJson(data)).toList();
  }

  Future<void> recordPropertyView({
    required String propertyId,
    required String userId,
  }) async {
    await client.from('property_views').insert({
      'property_id': propertyId,
      'user_id': userId,
      'viewed_at': DateTime.now().toIso8601String(),
    });
  }

  // Report methods
  Future<List<Report>> getUserReports(String userId) async {
    final response = await client
        .from('reports')
        .select()
        .eq('reporter_id', userId)
        .order('created_at', ascending: false);
    return response.map((data) => Report.fromJson(data)).toList();
  }

  Future<void> createReport({
    required String reporterId,
    required String reportedId,
    required String reportType,
    required String reason,
    String? description,
  }) async {
    await client.from('reports').insert({
      'reporter_id': reporterId,
      'reported_id': reportedId,
      'report_type': reportType,
      'reason': reason,
      'description': description,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Support Ticket methods
  Future<List<SupportTicket>> getUserSupportTickets(String userId) async {
    final response = await client
        .from('support_tickets')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return response.map((data) => SupportTicket.fromJson(data)).toList();
  }

  Future<void> createSupportTicket({
    required String userId,
    required String subject,
    required String description,
    required String category,
  }) async {
    await client.from('support_tickets').insert({
      'user_id': userId,
      'subject': subject,
      'description': description,
      'category': category,
      'status': 'open',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Saved Search methods
  Future<List<SavedSearch>> getUserSavedSearches(String userId) async {
    final response = await client
        .from('saved_searches')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return response.map((data) => SavedSearch.fromJson(data)).toList();
  }

  Future<void> createSavedSearch({
    required String userId,
    required String searchName,
    required Map<String, dynamic> searchCriteria,
  }) async {
    await client.from('saved_searches').insert({
      'user_id': userId,
      'search_name': searchName,
      'search_criteria': searchCriteria,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteSavedSearch(String searchId) async {
    await client
        .from('saved_searches')
        .delete()
        .eq('id', searchId);
  }
}