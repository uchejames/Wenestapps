import 'package:flutter/material.dart';
import 'package:wenest/utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textColor,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            
            // Account Section
            _buildSectionHeader('Account'),
            _buildSettingsCard([
              _buildSettingsTile(
                icon: Icons.person_outline,
                iconColor: AppColors.primaryColor,
                title: 'Profile',
                subtitle: 'Manage your personal information',
                onTap: () {
                  // Navigate to profile settings
                },
              ),
              const Divider(height: 1, indent: 68),
              _buildSettingsTile(
                icon: Icons.notifications_outlined,
                iconColor: AppColors.accentColor,
                title: 'Notifications',
                subtitle: 'Configure notification preferences',
                onTap: () {
                  Navigator.pushNamed(context, '/notifications_settings');
                },
              ),
              const Divider(height: 1, indent: 68),
              _buildSettingsTile(
                icon: Icons.language_outlined,
                iconColor: AppColors.secondaryColor,
                title: 'Language',
                subtitle: 'English',
                onTap: () {
                  Navigator.pushNamed(context, '/language_selection');
                },
              ),
            ]),

            // Privacy & Security Section
            _buildSectionHeader('Privacy & Security'),
            _buildSettingsCard([
              _buildSettingsTile(
                icon: Icons.lock_outline,
                iconColor: AppColors.primaryColor,
                title: 'Privacy Policy',
                subtitle: 'Review our privacy practices',
                onTap: () {
                  Navigator.pushNamed(context, '/privacy_policy');
                },
              ),
              const Divider(height: 1, indent: 68),
              _buildSettingsTile(
                icon: Icons.description_outlined,
                iconColor: AppColors.lightTeal,
                title: 'Terms and Conditions',
                subtitle: 'Read our terms of service',
                onTap: () {
                  Navigator.pushNamed(context, '/terms_and_conditions');
                },
              ),
            ]),

            // Support Section
            _buildSectionHeader('Support'),
            _buildSettingsCard([
              _buildSettingsTile(
                icon: Icons.help_outline,
                iconColor: AppColors.accentColor,
                title: 'Help & Support',
                subtitle: 'Get assistance from our team',
                onTap: () {
                  Navigator.pushNamed(context, '/help_support');
                },
              ),
              const Divider(height: 1, indent: 68),
              _buildSettingsTile(
                icon: Icons.quiz_outlined,
                iconColor: AppColors.secondaryColor,
                title: 'FAQ',
                subtitle: 'Find answers to common questions',
                onTap: () {
                  Navigator.pushNamed(context, '/faq');
                },
              ),
            ]),

            // About Section
            _buildSectionHeader('About'),
            _buildSettingsCard([
              _buildSettingsTile(
                icon: Icons.info_outline,
                iconColor: AppColors.primaryColor,
                title: 'About WeNest',
                subtitle: 'Version 1.0.0',
                onTap: () {
                  _showAboutDialog(context);
                },
              ),
              const Divider(height: 1, indent: 68),
              _buildSettingsTile(
                icon: Icons.share_outlined,
                iconColor: AppColors.accentColor,
                title: 'Share App',
                subtitle: 'Recommend WeNest to friends',
                onTap: () {
                  // Share app functionality
                },
              ),
              const Divider(height: 1, indent: 68),
              _buildSettingsTile(
                icon: Icons.star_outline,
                iconColor: Colors.amber,
                title: 'Rate Us',
                subtitle: 'Leave a review on the app store',
                onTap: () {
                  // Rate app functionality
                },
              ),
            ]),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey.shade400,
      ),
      onTap: onTap,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.info_outline,
                color: AppColors.primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'About WeNest',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.appTagline,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'WeNest is your trusted platform for finding the perfect property. We connect property seekers with verified agencies and landlords across Nigeria.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}