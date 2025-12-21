import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wenest_app/utils/constants.dart';

class UserMessagesScreen extends StatefulWidget {
  const UserMessagesScreen({super.key});

  @override
  State<UserMessagesScreen> createState() => _UserMessagesScreenState();
}

class _UserMessagesScreenState extends State<UserMessagesScreen> {
  final List<Map<String, dynamic>> _conversations = [
    {
      'name': 'Premium Estates Ltd',
      'lastMessage':
          'Hello! Thanks for your interest in the 3-bedroom apartment...',
      'time': '2:30 PM',
      'unread': true,
      'avatar': Icons.business,
    },
    {
      'name': 'John Landlord',
      'lastMessage':
          'The property is still available. Would you like to schedule a visit?',
      'time': '11:45 AM',
      'unread': false,
      'avatar': Icons.person,
    },
    {
      'name': 'Urban Homes Agency',
      'lastMessage': 'We have new properties that match your search criteria.',
      'time': 'Yesterday',
      'unread': true,
      'avatar': Icons.business,
    },
    {
      'name': 'Sarah Agent',
      'lastMessage':
          'Thanks for getting back to me. I\'ll send you the documents.',
      'time': 'Yesterday',
      'unread': false,
      'avatar': Icons.person,
    },
    {
      'name': 'Metropolitan Properties',
      'lastMessage': 'Special offer: 10% discount on 6-month lease!',
      'time': 'Dec 15',
      'unread': false,
      'avatar': Icons.business,
    },
  ];

  bool _isLoading = false;

  Future<void> _refreshMessages() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate network request
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Handle search
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Handle more options
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshMessages,
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search messages...',
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(15),
                  ),
                ),
              ),
            ),
            // Conversations list
            Expanded(
              child: _isLoading
                  ? _buildShimmerList()
                  : ListView.builder(
                      itemCount: _conversations.length,
                      itemBuilder: (context, index) {
                        final conversation = _conversations[index];
                        return _buildConversationTile(conversation);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Create new message
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.message),
      ),
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> conversation) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryColor,
        child: Icon(
          conversation['avatar'],
          color: Colors.white,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation['name'],
              style: TextStyle(
                fontWeight: conversation['unread']
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          Text(
            conversation['time'],
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              conversation['lastMessage'],
              style: TextStyle(
                color: conversation['unread'] ? Colors.black : Colors.grey,
                fontWeight: conversation['unread']
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conversation['unread'])
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      onTap: () {
        // Open conversation
      },
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar placeholder
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 15),
                  // Text content placeholders
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name placeholder
                        Container(
                          height: 20,
                          width: 120,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 10),
                        // Message placeholder
                        Container(
                          height: 15,
                          width: double.infinity,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 5),
                        // Time placeholder
                        Container(
                          height: 12,
                          width: 60,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  // Unread indicator placeholder
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
