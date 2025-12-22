import 'package:flutter/material.dart';
import 'package:wenest/utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Section
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.person, color: AppColors.primaryColor),
                title: const Text('Profile'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to profile settings
                },
              ),
            ),
            // Notifications Section
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.notifications, color: AppColors.primaryColor),
                title: const Text('Notifications'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pushNamed(context, '/notifications_settings');
                },
              ),
            ),
            // Language Section
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.language, color: AppColors.primaryColor),
                title: const Text('Language'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pushNamed(context, '/language_selection');
                },
              ),
            ),
            // Privacy & Security Section
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 30, 16, 10),
              child: Text(
                'PRIVACY & SECURITY',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.lock, color: AppColors.primaryColor),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pushNamed(context, '/privacy_policy');
                },
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.description, color: AppColors.primaryColor),
                title: const Text('Terms and Conditions'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pushNamed(context, '/terms_and_conditions');
                },
              ),
            ),
            // Support Section
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 30, 16, 10),
              child: Text(
                'SUPPORT',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.help, color: AppColors.primaryColor),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pushNamed(context, '/help_support');
                },
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.question_answer, color: AppColors.primaryColor),
                title: const Text('FAQ'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pushNamed(context, '/faq');
                },
              ),
            ),
            // About Section
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 30, 16, 10),
              child: Text(
                'ABOUT',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.info, color: AppColors.primaryColor),
                title: const Text('About WeNest'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Show about dialog
                },
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.share, color: AppColors.primaryColor),
                title: const Text('Share App'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Share app functionality
                },
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.rate_review, color: AppColors.primaryColor),
                title: const Text('Rate Us'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Rate app functionality
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}