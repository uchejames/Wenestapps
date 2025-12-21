import 'package:flutter/material.dart';
import 'package:wenest_app/utils/constants.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How can we help you?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Browse our help topics or contact us directly',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            // Search bar
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search help topics...',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(15),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Help categories
            const Text(
              'Popular Topics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildHelpCard(
              context,
              'Account & Profile',
              'Managing your account, profile settings, and personal information',
              Icons.person,
            ),
            const SizedBox(height: 15),
            _buildHelpCard(
              context,
              'Property Listings',
              'Searching, saving, and applying for properties',
              Icons.house,
            ),
            const SizedBox(height: 15),
            _buildHelpCard(
              context,
              'Payments & Billing',
              'Understanding fees, payment methods, and billing',
              Icons.payment,
            ),
            const SizedBox(height: 15),
            _buildHelpCard(
              context,
              'Agency Verification',
              'Process and requirements for agency verification',
              Icons.verified,
            ),
            const SizedBox(height: 15),
            _buildHelpCard(
              context,
              'Safety & Security',
              'Protecting your account and staying safe on WeNest',
              Icons.security,
            ),
            const SizedBox(height: 40),
            // Contact support
            const Text(
              'Need More Help?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.email,
                    color: AppColors.primaryColor,
                  ),
                ),
                title: const Text('Email Support'),
                subtitle: const Text('Get help via email within 24 hours'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Open email support
                },
              ),
            ),
            const SizedBox(height: 15),
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.chat,
                    color: AppColors.primaryColor,
                  ),
                ),
                title: const Text('Live Chat'),
                subtitle: const Text('Chat with our support team now'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Open live chat
                },
              ),
            ),
            const SizedBox(height: 15),
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.phone,
                    color: AppColors.primaryColor,
                  ),
                ),
                title: const Text('Call Us'),
                subtitle: const Text('Speak with a representative'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Call support
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
  ) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryColor,
          ),
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigate to specific help topic
        },
      ),
    );
  }
}
