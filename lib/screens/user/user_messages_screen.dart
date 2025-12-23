import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wenest/utils/constants.dart';

class UserMessagesScreen extends StatefulWidget {
  const UserMessagesScreen({super.key});

  @override
  State<UserMessagesScreen> createState() => _UserMessagesScreenState();
}

class _UserMessagesScreenState extends State<UserMessagesScreen> {
  final _searchController = TextEditingController();
  final List<Map<String, dynamic>> _conversations = [
    {
      'name': 'Premium Estates Ltd',
      'lastMessage': 'Hello! Thanks for your interest in the 3-bedroom apartment...',
      'time': '2:30 PM',
      'unread': true,
      'avatar': Icons.business_rounded,
      'isAgency': true,
    },
    {
      'name': 'John Landlord',
      'lastMessage': 'The property is still available. Would you like to schedule a visit?',
      'time': '11:45 AM',
      'unread': false,
      'avatar': Icons.person_rounded,
      'isAgency': false,
    },
    {
      'name': 'Urban Homes Agency',
      'lastMessage': 'We have new properties that match your search criteria.',
      'time': 'Yesterday',
      'unread': true,
      'avatar': Icons.business_rounded,
      'isAgency': true,
    },
    {
      'name': 'Sarah Agent',
      'lastMessage': 'Thanks for getting back to me. I\'ll send you the documents.',
      'time': 'Yesterday',
      'unread': false,
      'avatar': Icons.person_rounded,
      'isAgency': false,
    },
    {
      'name': 'Metropolitan Properties',
      'lastMessage': 'Special offer: 10% discount on 6-month lease!',
      'time': 'Dec 15',
      'unread': false,
      'avatar': Icons.business_rounded,
      'isAgency': true,
    },
  ];

  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshMessages() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.primaryColor),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshMessages,
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
                  decoration: InputDecoration(
                    hintText: 'Search messages...',
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
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _conversations.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index < _conversations.length - 1 ? 12 : 0,
                          ),
                          child: _buildConversationCard(_conversations[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('New message functionality coming soon'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Message', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> conversation) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Chat functionality coming soon'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: conversation['unread'] 
              ? AppColors.primaryColor.withValues(alpha: 0.03)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: conversation['unread']
                ? AppColors.primaryColor.withValues(alpha: 0.2)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                conversation['avatar'],
                color: AppColors.primaryColor,
                size: 28,
              ),
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
                        child: Text(
                          conversation['name'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: conversation['unread'] ? FontWeight.bold : FontWeight.w600,
                            color: AppColors.textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        conversation['time'],
                        style: TextStyle(
                          color: conversation['unread'] ? AppColors.primaryColor : Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight: conversation['unread'] ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation['lastMessage'],
                          style: TextStyle(
                            color: conversation['unread'] ? Colors.grey.shade700 : Colors.grey.shade600,
                            fontSize: 14,
                            fontWeight: conversation['unread'] ? FontWeight.w500 : FontWeight.normal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation['unread'])
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryColor,
                            shape: BoxShape.circle,
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