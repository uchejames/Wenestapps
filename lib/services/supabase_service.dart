import 'package:supabase/supabase.dart';
import 'package:wenest_app/models/profile.dart';
import 'package:wenest_app/models/agency.dart';
import 'package:wenest_app/models/agent.dart';
import 'package:wenest_app/models/landlord.dart';
import 'package:wenest_app/models/property.dart';
import 'package:wenest_app/models/property_media.dart';
import 'package:wenest_app/models/amenity.dart';
import 'package:wenest_app/models/property_amenity.dart';
import 'package:wenest_app/models/review.dart';
import 'package:wenest_app/models/favorite.dart';
import 'package:wenest_app/models/conversation.dart';
import 'package:wenest_app/models/message.dart';
import 'package:wenest_app/models/notification.dart' as app_notification;import 'package:wenest_app/models/transaction.dart';
import 'package:wenest_app/models/subscription.dart';
import 'package:wenest_app/models/property_view.dart';
import 'package:wenest_app/models/report.dart';
import 'package:wenest_app/models/support_ticket.dart';
import 'package:wenest_app/models/saved_search.dart';
import 'package:wenest_app/utils/config.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://gcbpxkwwscylyjemdpcd.supabase.co';
  static const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdjYnB4a3d3c2N5bHlqZW1kcGNkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc2NTcyMzksImV4cCI6MjA2MzIzMzIzOX0.l-HRTFc3LjV3ULWRCUjrKgMfsY95voNn22pkwin0iVA';

  late SupabaseClient _client;

  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() => _instance;

  SupabaseService._internal() {
    _client = SupabaseClient(supabaseUrl, supabaseKey);
  }

  SupabaseClient get client => _client;

  // Auth methods
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: userData,
    );
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // User methods
  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  Stream<AuthState> authStateChanges() {
    return _client.auth.onAuthStateChange;
  }

  // Profile methods
  Future<Profile?> getProfile(String id) async {
    final response =
        await _client.from('profiles').select().eq('id', id).single();
    return response != null ? Profile.fromJson(response) : null;
  }

  Future<List<Profile>> getAllProfiles() async {
    final response = await _client
        .from('profiles')
        .select()
        .order('created_at', ascending: false);
    return response.map((data) => Profile.fromJson(data)).toList();
  }

  // Agency methods
  Future<List<Agency>> getAgencies() async {
    final response = await _client
        .from('agencies')
        .select()
        .eq('verified', true)
        .order('created_at', ascending: false);
    return response.map((data) => Agency.fromJson(data)).toList();
  }

  Future<Agency?> getAgencyById(String id) async {
    final response =
        await _client.from('agencies').select().eq('id', id).single();
    return response != null ? Agency.fromJson(response) : null;
  }

  // Agent methods
  Future<List<Agent>> getAgents() async {
    final response = await _client
        .from('agents')
        .select()
        .eq('verified', true)
        .eq('is_active', true)
        .order('created_at', ascending: false);
    return response.map((data) => Agent.fromJson(data)).toList();
  }

  Future<Agent?> getAgentById(String id) async {
    final response =
        await _client.from('agents').select().eq('id', id).single();
    return response != null ? Agent.fromJson(response) : null;
  }

  // Landlord methods
  Future<List<Landlord>> getLandlords() async {
    final response = await _client
        .from('landlords')
        .select()
        .eq('verified', true)
        .order('created_at', ascending: false);
    return response.map((data) => Landlord.fromJson(data)).toList();
  }

  Future<Landlord?> getLandlordById(String id) async {
    final response =
        await _client.from('landlords').select().eq('id', id).single();
    return response != null ? Landlord.fromJson(response) : null;
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
    var query = _client
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
    final response = await _client
        .from('properties')
        .select()
        .eq('id', id)
        .eq('is_approved', true)
        .eq('status', 'active')
        .single();
    return response != null ? Property.fromJson(response) : null;
  }

  // Property Media methods
  Future<List<PropertyMedia>> getPropertyMedia(String propertyId) async {
    final response = await _client
        .from('property_media')
        .select()
        .eq('property_id', propertyId)
        .order('display_order', ascending: true);
    return response.map((data) => PropertyMedia.fromJson(data)).toList();
  }

  // Amenity methods
  Future<List<Amenity>> getAmenities() async {
    final response = await _client
        .from('amenities_master')
        .select()
        .order('name', ascending: true);
    return response.map((data) => Amenity.fromJson(data)).toList();
  }

  // Property Amenity methods
  Future<List<PropertyAmenity>> getPropertyAmenities(String propertyId) async {
    final response = await _client
        .from('property_amenities')
        .select()
        .eq('property_id', propertyId);
    return response.map((data) => PropertyAmenity.fromJson(data)).toList();
  }

  // Review methods
  Future<List<Review>> getPropertyReviews(String propertyId) async {
    final response = await _client
        .from('reviews')
        .select()
        .eq('property_id', propertyId)
        .order('created_at', ascending: false);
    return response.map((data) => Review.fromJson(data)).toList();
  }

  // Favorite methods
  Future<List<Favorite>> getUserFavorites(String userId) async {
    final response = await _client
        .from('favorites')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return response.map((data) => Favorite.fromJson(data)).toList();
  }

  // Conversation methods
  Future<List<Conversation>> getUserConversations(String userId) async {
    final response = await _client
        .from('conversations')
        .select()
        .or('initiator_id.eq.$userId,receiver_id.eq.$userId')
        .order('updated_at', ascending: false);
    return response.map((data) => Conversation.fromJson(data)).toList();
  }

  // Message methods
  Future<List<Message>> getConversationMessages(String conversationId) async {
    final response = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
    return response.map((data) => Message.fromJson(data)).toList();
  }

  // Notification methods
  Future<List<app_notification.Notification>> getUserNotifications(String userId) async {
    final response = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return response.map((data) => app_notification.Notification.fromJson(data)).toList();
  }  // Transaction methods
  Future<List<Transaction>> getUserTransactions(String userId) async {
    final response = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return response.map((data) => Transaction.fromJson(data)).toList();
  }

  // Subscription methods
  Future<List<Subscription>> getAgencySubscriptions(String agencyId) async {
    final response = await _client
        .from('subscriptions')
        .select()
        .eq('agency_id', agencyId)
        .order('created_at', ascending: false);
    return response.map((data) => Subscription.fromJson(data)).toList();
  }

  // Property View methods
  Future<List<PropertyView>> getPropertyViews(String propertyId) async {
    final response = await _client
        .from('property_views')
        .select()
        .eq('property_id', propertyId)
        .order('viewed_at', ascending: false);
    return response.map((data) => PropertyView.fromJson(data)).toList();
  }

  // Report methods
  Future<List<Report>> getUserReports(String userId) async {
    final response = await _client
        .from('reports')
        .select()
        .eq('reporter_id', userId)
        .order('created_at', ascending: false);
    return response.map((data) => Report.fromJson(data)).toList();
  }

  // Support Ticket methods
  Future<List<SupportTicket>> getUserSupportTickets(String userId) async {
    final response = await _client
        .from('support_tickets')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return response.map((data) => SupportTicket.fromJson(data)).toList();
  }

  // Saved Search methods
  Future<List<SavedSearch>> getUserSavedSearches(String userId) async {
    final response = await _client
        .from('saved_searches')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return response.map((data) => SavedSearch.fromJson(data)).toList();
  }
}