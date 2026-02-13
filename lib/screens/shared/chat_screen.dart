import 'package:flutter/material.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/services/supabase_service.dart';
import 'package:wenest/services/messaging_service.dart';
import 'package:wenest/models/message.dart';
import 'package:wenest/models/profile.dart';
import 'package:wenest/models/property.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final Profile otherUser;
  final Property? propertyContext; // Optional property reference

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUser,
    this.propertyContext,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _supabaseService = SupabaseService();
  late final MessagingService _messagingService;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  
  List<Message> _messages = [];
  List<String> _optimisticMessageIds = []; // Track optimistic messages
  bool _isLoading = true;
  bool _isSending = false;
  String _error = '';
  RealtimeChannel? _messageChannel;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _messagingService = MessagingService(_supabaseService.client);
    _currentUserId = _supabaseService.getCurrentUser()?.id;
    _loadMessages();
    _subscribeToMessages();
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    if (_messageChannel != null) {
      _messagingService.unsubscribeFromChannel(_messageChannel!);
    }
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final messages = await _messagingService.getMessages(
        conversationId: widget.conversationId,
      );
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _subscribeToMessages() {
    _messageChannel = _messagingService.subscribeToConversation(
      conversationId: widget.conversationId,
      onNewMessage: (message) {
        setState(() {
          // Remove optimistic message if it exists
          if (_optimisticMessageIds.contains(message.id)) {
            _optimisticMessageIds.remove(message.id);
            // Replace optimistic with real message
            final index = _messages.indexWhere((m) => m.id == message.id);
            if (index != -1) {
              _messages[index] = message;
            }
          } else {
            _messages.add(message);
          }
        });
        _scrollToBottom();
        
        // Mark as read if it's from the other user
        if (message.senderId != _currentUserId) {
          _markMessagesAsRead();
        }
      },
    );
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await _messagingService.markMessagesAsRead(
        conversationId: widget.conversationId,
      );
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<void> _sendMessage({String? propertyId}) async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    final messageText = _messageController.text;
    _messageController.clear();

    // Create optimistic message ID
    final optimisticId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    
    // Create optimistic message and add to list immediately
    final optimisticMessage = Message(
      id: optimisticId,
      conversationId: widget.conversationId,
      senderId: _currentUserId!,
      receiverId: widget.otherUser.id,
      content: messageText,
      propertyId: propertyId ?? widget.propertyContext?.id,
      isRead: false,
      sentAt: DateTime.now(),  // FIXED: Changed from createdAt to sentAt
      updatedAt: DateTime.now(),
    );

    setState(() {
      _messages.add(optimisticMessage);
      _optimisticMessageIds.add(optimisticId);
    });
    _scrollToBottom();

    try {
      await _messagingService.sendMessage(
        conversationId: widget.conversationId,
        receiverId: widget.otherUser.id,
        content: messageText,
        propertyId: propertyId ?? widget.propertyContext?.id,
      );
      
      // The real message will replace the optimistic one via realtime subscription
    } catch (e) {
      // Remove optimistic message on error
      setState(() {
        _messages.removeWhere((m) => m.id == optimisticId);
        _optimisticMessageIds.remove(optimisticId);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
          ),
        );
        _messageController.text = messageText; // Restore message
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryColor),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                image: widget.otherUser.avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(widget.otherUser.avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: widget.otherUser.avatarUrl == null
                  ? Icon(
                      _getUserTypeIcon(widget.otherUser.userType),
                      color: AppColors.primaryColor,
                      size: 20,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.fullName ?? 'Unknown User',
                    style: const TextStyle(
                      color: AppColors.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _getUserTypeLabel(widget.otherUser.userType),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.primaryColor),
            onPressed: () {
              _showOptionsMenu();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Property Context Card (if available)
          if (widget.propertyContext != null)
            _buildPropertyContextCard(widget.propertyContext!),

          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? _buildErrorState()
                    : _messages.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(20),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final isMe = message.senderId == _currentUserId;
                              final showDateHeader = _shouldShowDateHeader(index);
                              final isOptimistic = _optimisticMessageIds.contains(message.id);

                              return Column(
                                children: [
                                  if (showDateHeader)
                                    _buildDateHeader(_messages[index].createdAt),
                                  
                                  // Property reference in message
                                  if (message.propertyId != null && message.propertyId!.isNotEmpty)
                                    _buildPropertyReferenceCard(message.propertyId!, isMe),
                                  
                                  _buildMessageBubble(message, isMe, isOptimistic),
                                ],
                              );
                            },
                          ),
          ),

          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildPropertyContextCard(Property property) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade200,
            ),
            child: const Icon(Icons.home_rounded, color: AppColors.primaryColor, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inquiring about:',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  property.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  property.formattedPrice,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, size: 20),
            color: AppColors.primaryColor,
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/property_detail',
                arguments: property.id,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyReferenceCard(String propertyId, bool isMe) {
    return FutureBuilder<Property?>(
      future: _supabaseService.getPropertyById(propertyId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            margin: EdgeInsets.only(
              left: isMe ? 60 : 48,
              right: isMe ? 48 : 60,
              bottom: 8,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Loading property...', style: TextStyle(fontSize: 12)),
              ],
            ),
          );
        }

        if (snapshot.data == null) return const SizedBox.shrink();

        final property = snapshot.data!;
        
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/property_detail',
              arguments: property.id,
            );
          },
          child: Container(
            margin: EdgeInsets.only(
              left: isMe ? 60 : 48,
              right: isMe ? 48 : 60,
              bottom: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(Icons.home_rounded, size: 40, color: Colors.grey),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.open_in_new_rounded, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'View',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        property.formattedPrice,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 12, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              property.locationDisplay,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _shouldShowDateHeader(int index) {
    if (index == 0) return true;
    
    final currentMessage = _messages[index];
    final previousMessage = _messages[index - 1];
    
    final currentDate = DateTime(
      currentMessage.createdAt.year,
      currentMessage.createdAt.month,
      currentMessage.createdAt.day,
    );
    
    final previousDate = DateTime(
      previousMessage.createdAt.year,
      previousMessage.createdAt.month,
      previousMessage.createdAt.day,
    );
    
    return !currentDate.isAtSameMomentAs(previousDate);
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    
    String dateText;
    if (messageDate.isAtSameMomentAs(today)) {
      dateText = 'Today';
    } else if (messageDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      dateText = 'Yesterday';
    } else {
      dateText = '${date.day}/${date.month}/${date.year}';
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateText,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Material(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _isSending ? null : _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe, bool isOptimistic) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                image: widget.otherUser.avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(widget.otherUser.avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: widget.otherUser.avatarUrl == null
                  ? Icon(
                      _getUserTypeIcon(widget.otherUser.userType),
                      color: AppColors.primaryColor,
                      size: 16,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Opacity(
              opacity: isOptimistic ? 0.6 : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.primaryColor : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isMe ? Colors.white : AppColors.textColor,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isOptimistic)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isMe ? Colors.white.withValues(alpha: 0.7) : Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ),
                        Text(
                          timeago.format(message.createdAt),
                          style: TextStyle(
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.7)
                                : Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                        if (isMe && !isOptimistic) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead
                                ? Icons.done_all_rounded
                                : Icons.done_rounded,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 14,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getUserTypeIcon(String userType) {
    switch (userType.toLowerCase()) {
      case 'agency':
        return Icons.business_rounded;
      case 'agent':
        return Icons.badge_rounded;
      case 'landlord':
        return Icons.home_work_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  String _getUserTypeLabel(String userType) {
    switch (userType.toLowerCase()) {
      case 'agency':
        return 'Agency';
      case 'agent':
        return 'Agent';
      case 'landlord':
        return 'Landlord';
      default:
        return 'User';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation by sending a message',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 80, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Error loading messages',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _error,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadMessages,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_rounded, color: AppColors.primaryColor),
                title: const Text('View Profile'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to user profile
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile view coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: Colors.red),
                title: const Text('Delete Conversation', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteConversation();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteConversation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text('Are you sure you want to delete this conversation? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _messagingService.deleteConversation(widget.conversationId);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conversation deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting conversation: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}