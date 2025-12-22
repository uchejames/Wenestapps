import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wenest/utils/constants.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'New Message',
      'body': 'John from Premium Estates sent you a message',
      'time': '2 mins ago',
      'isRead': false,
      'type': 'message',
    },
    {
      'title': 'Property Update',
      'body': '3 Bedroom Apartment in Lekki has been updated',
      'time': '1 hour ago',
      'isRead': false,
      'type': 'property',
    },
    {
      'title': 'Booking Confirmation',
      'body': 'Your property viewing has been confirmed',
      'time': '3 hours ago',
      'isRead': true,
      'type': 'booking',
    },
    {
      'title': 'New Review',
      'body': 'You received a 5-star review',
      'time': '1 day ago',
      'isRead': true,
      'type': 'review',
    },
    {
      'title': 'Verification Approved',
      'body': 'Your agency verification has been approved',
      'time': '2 days ago',
      'isRead': true,
      'type': 'verification',
    },
  ];

  bool _isLoading = false;

  Future<void> _refreshNotifications() async {
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
        title: const Text('Notifications'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications_settings');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNotifications,
        child: Column(
          children: [
            // Filter tabs
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: true,
                    selectedColor: AppColors.primaryColor,
                    onSelected: (selected) {},
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text('Unread'),
                    selected: false,
                    selectedColor: AppColors.primaryColor,
                    onSelected: (selected) {},
                  ),
                ],
              ),
            ),
            // Notifications list
            Expanded(
              child: _isLoading
                  ? _buildShimmerList()
                  : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return _buildNotificationItem(notification);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    IconData iconData;
    Color iconColor;

    switch (notification['type']) {
      case 'message':
        iconData = Icons.message;
        iconColor = AppColors.primaryColor;
        break;
      case 'property':
        iconData = Icons.house;
        iconColor = AppColors.secondaryColor;
        break;
      case 'booking':
        iconData = Icons.calendar_today;
        iconColor = AppColors.accentColor;
        break;
      case 'review':
        iconData = Icons.star;
        iconColor = Colors.amber;
        break;
      case 'verification':
        iconData = Icons.verified;
        iconColor = Colors.green;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = AppColors.primaryColor;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            iconData,
            color: iconColor,
          ),
        ),
        title: Text(
          notification['title'],
          style: TextStyle(
            fontWeight:
                notification['isRead'] ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text(notification['body']),
        trailing: Text(
          notification['time'],
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        onTap: () {
          // Navigate to notification details
          Navigator.pushNamed(context, '/notifications_details');
        },
      ),
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
                  // Icon placeholder
                  Container(
                    width: 40,
                    height: 40,
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
                        // Title placeholder
                        Container(
                          height: 20,
                          width: 120,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 10),
                        // Body placeholder
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
