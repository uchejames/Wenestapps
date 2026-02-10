import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/services/supabase_service.dart';
import 'package:wenest/services/messaging_service.dart';
import 'package:wenest/models/conversation.dart';
import 'package:wenest/models/profile.dart';
import 'package:wenest/screens/shared/chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _supabaseService = SupabaseService();
  late final MessagingService _messagingService;
  final _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _filteredConversations = [];
  bool _isLoading = true;
  String _error = '';
  RealtimeChannel? _conversationsChannel;

  @override
  void initState() {
    super.initState();
    _messagingService = MessagingService(_supabaseService.client);
    _loadConversations();
    _subscribeToConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_conversationsChannel != null) {
      _messagingService.unsubscribeFromChannel(_conversationsChannel!);
    }
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final conversations = await _messagingService.getUserConversations();
      setState(() {
        _conversations = conversations;
        _filteredConversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _subscribeToConversations() {
    final userId = _supabaseService.getCurrentUser()?.id;
    if (userId == null) return;

    _conversationsChannel = _messagingService.subscribeToUserConversations(
      userId: userId,
      onConversationUpdate: () {
        _loadConversations();
      },
    );
  }

  void _filterConversations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredConversations = _conversations;
      } else {
        _filteredConversations = _conversations.where((conv) {
          final otherUser = conv['otherUser'] as Profile;
          return (otherUser.fullName?.toLowerCase() ?? '').contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _deleteConversation(String conversationId) async {
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
        await _messagingService.deleteConversation(conversationId);
        _loadConversations();
        if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadConversations,
        color: AppColors.primaryColor,
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterConversations,
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 22),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // Conversations List
            Expanded(
              child: _isLoading
                  ? _buildShimmerList()
                  : _error.isNotEmpty
                      ? _buildErrorState()
                      : _filteredConversations.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _filteredConversations.length,
                              itemBuilder: (context, index) {
                                final conv = _filteredConversations[index];
                                final conversation = conv['conversation'] as Conversation;
                                final otherUser = conv['otherUser'] as Profile;
                                final unreadCount = conv['unreadCount'] as int;

                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index < _filteredConversations.length - 1 ? 12 : 0,
                                  ),
                                  child: _buildConversationCard(
                                    conversation: conversation,
                                    otherUser: otherUser,
                                    unreadCount: unreadCount,
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'messages_fab',
        onPressed: () {
          _showNewMessageDialog();
        },
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Message', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  void _showNewMessageDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _NewMessageSheet(
          messagingService: _messagingService,
          scrollController: scrollController,
          onConversationCreated: () {
            Navigator.pop(context);
            _loadConversations();
          },
        ),
      ),
    );
  }

  Widget _buildConversationCard({
    required Conversation conversation,
    required Profile otherUser,
    required int unreadCount,
  }) {
    final hasUnread = unreadCount > 0;
    String timeAgo = '';
    
    if (conversation.lastMessageAt != null) {
      timeAgo = timeago.format(conversation.lastMessageAt!);
    }

    return Dismissible(
      key: Key(conversation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Conversation'),
            content: const Text('Are you sure you want to delete this conversation?'),
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
      },
      onDismissed: (direction) {
        _deleteConversation(conversation.id);
      },
      child: GestureDetector(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                conversationId: conversation.id,
                otherUser: otherUser,
              ),
            ),
          );
          if (result == true) {
            _loadConversations();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: hasUnread
                ? AppColors.primaryColor.withValues(alpha: 0.03)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasUnread
                  ? AppColors.primaryColor.withValues(alpha: 0.2)
                  : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      image: otherUser.avatarUrl != null
                          ? DecorationImage(
                              image: NetworkImage(otherUser.avatarUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: otherUser.avatarUrl == null
                        ? Icon(
                            _getUserTypeIcon(otherUser.userType),
                            color: AppColors.primaryColor,
                            size: 28,
                          )
                        : null,
                  ),
                  if (hasUnread)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  otherUser.fullName ?? 'Unknown User',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                                    color: AppColors.textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              _buildUserTypeBadge(otherUser.userType),
                            ],
                          ),
                        ),
                        if (timeAgo.isNotEmpty)
                          Text(
                            timeAgo,
                            style: TextStyle(
                              color: hasUnread ? AppColors.primaryColor : Colors.grey.shade500,
                              fontSize: 12,
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      conversation.lastMessage ?? 'No messages yet',
                      style: TextStyle(
                        color: hasUnread ? Colors.grey.shade700 : Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildUserTypeBadge(String userType) {
    if (userType.toLowerCase() == 'user') return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        userType.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primaryColor,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation by tapping the button below',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
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
            'Error loading conversations',
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
            onPressed: _loadConversations,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade200,
            highlightColor: Colors.grey.shade50,
            child: Container(
              height: 86,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================
// NEW MESSAGE SHEET WIDGET
// ============================================

class _NewMessageSheet extends StatefulWidget {
  final MessagingService messagingService;
  final ScrollController scrollController;
  final VoidCallback onConversationCreated;

  const _NewMessageSheet({
    required this.messagingService,
    required this.scrollController,
    required this.onConversationCreated,
  });

  @override
  State<_NewMessageSheet> createState() => _NewMessageSheetState();
}

class _NewMessageSheetState extends State<_NewMessageSheet> {
  final _searchController = TextEditingController();
  List<Profile> _searchResults = [];
  bool _isSearching = false;
  String _error = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _error = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = '';
    });

    try {
      final results = await widget.messagingService.searchUsers(query.trim());
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSearching = false;
      });
    }
  }

  Future<void> _startConversation(Profile user) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final conversation = await widget.messagingService.getOrCreateConversation(
        otherUserId: user.id,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading
        widget.onConversationCreated();
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversation.id,
              otherUser: user,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'New Message',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (value) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _searchUsers(value);
                  }
                });
              },
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 22),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, color: Colors.grey.shade400),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _error = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline_rounded, size: 60, color: Colors.red.shade300),
                            const SizedBox(height: 16),
                            Text('Error searching users', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                          ],
                        ),
                      )
                    : _searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_rounded, size: 60, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isEmpty ? 'Search for users' : 'No users found',
                                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: widget.scrollController,
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final user = _searchResults[index];
                              return Padding(
                                padding: EdgeInsets.only(bottom: index < _searchResults.length - 1 ? 12 : 0),
                                child: _buildUserCard(user),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Profile user) {
    return GestureDetector(
      onTap: () => _startConversation(user),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                image: user.avatarUrl != null
                    ? DecorationImage(image: NetworkImage(user.avatarUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: user.avatarUrl == null
                  ? Icon(_getUserTypeIcon(user.userType), color: AppColors.primaryColor, size: 28)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.fullName ?? 'Unknown User',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildUserTypeBadge(user.userType),
                    ],
                  ),
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(user.bio!, style: TextStyle(color: Colors.grey.shade600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  if (user.city != null || user.state != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text([user.city, user.state].where((e) => e != null).join(', '), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey.shade400),
          ],
        ),
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

  Widget _buildUserTypeBadge(String userType) {
    if (userType.toLowerCase() == 'user') return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        userType.toUpperCase(),
        style: const TextStyle(color: AppColors.primaryColor, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}