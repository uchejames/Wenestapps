import 'package:flutter/material.dart';
import 'package:wenest/utils/constants.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool _enableNotifications = true;
  bool _enableSound = true;
  bool _enableVibration = true;
  bool _enableEmailNotifications = true;
  bool _enablePushNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Main notification toggle
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SwitchListTile(
                title: const Text('Enable Notifications'),
                value: _enableNotifications,
                onChanged: (bool value) {
                  setState(() {
                    _enableNotifications = value;
                  });
                },
                secondary: const Icon(Icons.notifications, color: AppColors.primaryColor),
              ),
            ),
            const SizedBox(height: 20),
            // Notification preferences
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(
                'NOTIFICATION PREFERENCES',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SwitchListTile(
                title: const Text('Sound'),
                value: _enableSound,
                onChanged: (bool value) {
                  setState(() {
                    _enableSound = value;
                  });
                },
                secondary: const Icon(Icons.volume_up, color: AppColors.primaryColor),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SwitchListTile(
                title: const Text('Vibration'),
                value: _enableVibration,
                onChanged: (bool value) {
                  setState(() {
                    _enableVibration = value;
                  });
                },
                secondary: const Icon(Icons.vibration, color: AppColors.primaryColor),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SwitchListTile(
                title: const Text('Push Notifications'),
                value: _enablePushNotifications,
                onChanged: (bool value) {
                  setState(() {
                    _enablePushNotifications = value;
                  });
                },
                secondary: const Icon(Icons.message, color: AppColors.primaryColor),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SwitchListTile(
                title: const Text('Email Notifications'),
                value: _enableEmailNotifications,
                onChanged: (bool value) {
                  setState(() {
                    _enableEmailNotifications = value;
                  });
                },
                secondary: const Icon(Icons.email, color: AppColors.primaryColor),
              ),
            ),
            const SizedBox(height: 30),
            // Notification categories
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(
                'NOTIFICATION CATEGORIES',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SwitchListTile(
                title: const Text('Messages'),
                subtitle: const Text('Chat and communication updates'),
                value: true,
                onChanged: (bool value) {},
                secondary: const Icon(Icons.chat, color: AppColors.primaryColor),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SwitchListTile(
                title: const Text('Property Updates'),
                subtitle: const Text('Changes to your saved properties'),
                value: true,
                onChanged: (bool value) {},
                secondary: const Icon(Icons.house, color: AppColors.primaryColor),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SwitchListTile(
                title: const Text('Bookings'),
                subtitle: const Text('Viewing appointments and confirmations'),
                value: true,
                onChanged: (bool value) {},
                secondary: const Icon(Icons.calendar_today, color: AppColors.primaryColor),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SwitchListTile(
                title: const Text('Reviews'),
                subtitle: const Text('Feedback on your properties or services'),
                value: true,
                onChanged: (bool value) {},
                secondary: const Icon(Icons.star, color: AppColors.primaryColor),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SwitchListTile(
                title: const Text('Verification'),
                subtitle: const Text('Account and property verification status'),
                value: true,
                onChanged: (bool value) {},
                secondary: const Icon(Icons.verified, color: AppColors.primaryColor),
              ),
            ),
            const SizedBox(height: 30),
            // Clear notifications
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // Clear all notifications
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Clear All Notifications',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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