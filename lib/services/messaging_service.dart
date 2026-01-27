import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wenest/models/conversation.dart';
import 'package:wenest/models/message.dart';
import 'package:wenest/models/profile.dart';
import 'package:flutter/foundation.dart';

class MessagingService {
  final SupabaseClient _client;

  MessagingService(this._client);

  // ============ CONVERSATION METHODS ============

  /// Get or create a conversation between two users
  Future<Conversation> getOrCreateConversation({
    required String otherUserId,
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Check if conversation already exists (either direction)
      final existingConversation = await _client
          .from('conversations')
          .select()
          .or('and(initiator_id.eq.$currentUserId,receiver_id.eq.$otherUserId),and(initiator_id.eq.$otherUserId,receiver_id.eq.$currentUserId)')
          .maybeSingle();

      if (existingConversation != null) {
        return Conversation.fromJson(existingConversation);
      }

      // Create new conversation
      final newConversation = await _client.from('conversations').insert({
        'initiator_id': currentUserId,
        'receiver_id': otherUserId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      return Conversation.fromJson(newConversation);
    } catch (e) {
      debugPrint('Error getting/creating conversation: $e');
      rethrow;
    }
  }

  /// Get all conversations for the current user
  Future<List<Map<String, dynamic>>> getUserConversations() async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get all conversations where user is either initiator or receiver
      final conversations = await _client
          .from('conversations')
          .select('''
            *,
            initiator:profiles!conversations_initiator_id_fkey(id, full_name, avatar_url, user_type),
            receiver:profiles!conversations_receiver_id_fkey(id, full_name, avatar_url, user_type)
          ''')
          .or('initiator_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .order('updated_at', ascending: false);

      // Process conversations to get the "other" user and unread count
      List<Map<String, dynamic>> processedConversations = [];
      
      for (var conv in conversations as List) {
        final isInitiator = conv['initiator_id'] == currentUserId;
        final otherUser = isInitiator ? conv['receiver'] : conv['initiator'];
        
        // Get unread count for this conversation
        final unreadMessages = await _client
            .from('messages')
            .select('id')
            .eq('conversation_id', conv['id'])
            .eq('receiver_id', currentUserId)
            .eq('is_read', false);

        processedConversations.add({
          'conversation': Conversation.fromJson(conv),
          'otherUser': Profile.fromJson(otherUser),
          'unreadCount': unreadMessages.length,
        });
      }

      return processedConversations;
    } catch (e) {
      debugPrint('Error getting user conversations: $e');
      rethrow;
    }
  }

  /// Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _client.from('conversations').delete().eq('id', conversationId);
    } catch (e) {
      debugPrint('Error deleting conversation: $e');
      rethrow;
    }
  }

  // ============ MESSAGE METHODS ============

  /// Send a message
  Future<Message> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    String? attachmentUrl,
    String messageType = 'text',
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Insert message
      final message = await _client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': currentUserId,
        'receiver_id': receiverId,
        'content': content,
        'attachment_url': attachmentUrl,
        'message_type': messageType,
        'is_read': false,
        'sent_at': DateTime.now().toIso8601String(),
      }).select().single();

      // Update conversation last_message and last_message_at
      await _client.from('conversations').update({
        'last_message': content,
        'last_message_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', conversationId);

      return Message.fromJson(message);
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  /// Get messages for a conversation with pagination
  Future<List<Message>> getMessages({
    required String conversationId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final messages = await _client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('sent_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (messages as List)
          .map((data) => Message.fromJson(data))
          .toList()
          .reversed
          .toList(); // Reverse to show oldest first
    } catch (e) {
      debugPrint('Error getting messages: $e');
      rethrow;
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead({
    required String conversationId,
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _client
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .eq('receiver_id', currentUserId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
      rethrow;
    }
  }

  /// Get unread message count for current user
  Future<int> getUnreadMessageCount() async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final result = await _client
          .from('messages')
          .select('id')
          .eq('receiver_id', currentUserId)
          .eq('is_read', false);

      return result.length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _client.from('messages').delete().eq('id', messageId);
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }

  // ============ REALTIME METHODS ============

  /// Subscribe to new messages in a conversation
  RealtimeChannel subscribeToConversation({
    required String conversationId,
    required Function(Message) onNewMessage,
  }) {
    final channel = _client.channel('conversation:$conversationId');
    
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            final message = Message.fromJson(payload.newRecord);
            onNewMessage(message);
          },
        )
        .subscribe();

    return channel;
  }

  /// Subscribe to conversation updates (for conversation list)
  RealtimeChannel subscribeToUserConversations({
    required String userId,
    required Function() onConversationUpdate,
  }) {
    final channel = _client.channel('user_conversations:$userId');
    
    // Listen for conversation updates
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'initiator_id',
            value: userId,
          ),
          callback: (payload) {
            onConversationUpdate();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: userId,
          ),
          callback: (payload) {
            onConversationUpdate();
          },
        )
        .subscribe();

    return channel;
  }

  /// Unsubscribe from a channel
  Future<void> unsubscribeFromChannel(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }

  // ============ SEARCH METHODS ============

  /// Search users to start a conversation with
  Future<List<Profile>> searchUsers(String query) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final users = await _client
          .from('profiles')
          .select()
          .neq('id', currentUserId)
          .ilike('full_name', '%$query%')
          .limit(20);

      return (users as List).map((data) => Profile.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      rethrow;
    }
  }

  // ============ UTILITY METHODS ============

  /// Check if user is part of a conversation
  Future<bool> isUserInConversation(String conversationId) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        return false;
      }

      final conversation = await _client
          .from('conversations')
          .select()
          .eq('id', conversationId)
          .or('initiator_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .maybeSingle();

      return conversation != null;
    } catch (e) {
      debugPrint('Error checking conversation membership: $e');
      return false;
    }
  }

  /// Get conversation by ID
  Future<Conversation?> getConversationById(String conversationId) async {
    try {
      final conversation = await _client
          .from('conversations')
          .select()
          .eq('id', conversationId)
          .single();

      return Conversation.fromJson(conversation);
    } catch (e) {
      debugPrint('Error getting conversation: $e');
      return null;
    }
  }
}