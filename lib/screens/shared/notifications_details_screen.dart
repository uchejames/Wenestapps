import 'package:flutter/material.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/models/notification.dart' as app_notification;
class NotificationsDetailsScreen extends StatelessWidget {
  const NotificationsDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // In a real app, you would get the notification data from the route arguments
    // For now, we'll use mock data
    final notification = app_notification.Notification(
      id: '1',
      userId: 'user123',
      title: 'New Message',
      body: 'John from Premium Estates sent you a message about the 3 Bedroom Apartment in Lekki. He mentioned that the property is still available and would like to schedule a viewing for tomorrow.',
      type: 'message',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Details'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.message,
                    color: AppColors.primaryColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${notification.createdAt.hour}:${notification.createdAt.minute.toString().padLeft(2, '0')} ${notification.createdAt.day}/${notification.createdAt.month}/${notification.createdAt.year}',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Notification content
            const Text(
              'Message Content',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                notification.body,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Action buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to messages or relevant screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'View Conversation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // Mark as unread or delete
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Mark as Unread',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}