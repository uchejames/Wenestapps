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

  // Category toggles
  bool _messagesEnabled = true;
  bool _propertyUpdatesEnabled = true;
  bool _bookingsEnabled = true;
  bool _reviewsEnabled = true;
  bool _verificationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Notification Settings',
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

            // Master toggle
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryColor,
                    AppColors.lightTeal,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _enableNotifications ? 'Enabled' : 'Disabled',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 0.9,
                    child: Switch(
                      value: _enableNotifications,
                      onChanged: (value) {
                        setState(() {
                          _enableNotifications = value;
                        });
                      },
                      activeColor: AppColors.accentColor,
                      activeTrackColor: Colors.white.withValues(alpha: 0.5),
                      inactiveThumbColor: Colors.white.withValues(alpha: 0.7),
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),

            // Notification Preferences
            _buildSectionHeader('Notification Preferences'),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: Icons.volume_up_outlined,
                iconColor: AppColors.accentColor,
                title: 'Sound',
                subtitle: 'Play sound for new notifications',
                value: _enableSound,
                onChanged: (value) {
                  setState(() {
                    _enableSound = value;
                  });
                },
              ),
              const Divider(height: 1, indent: 76),
              _buildSwitchTile(
                icon: Icons.vibration,
                iconColor: AppColors.primaryColor,
                title: 'Vibration',
                subtitle: 'Vibrate on new notifications',
                value: _enableVibration,
                onChanged: (value) {
                  setState(() {
                    _enableVibration = value;
                  });
                },
              ),
              const Divider(height: 1, indent: 76),
              _buildSwitchTile(
                icon: Icons.notifications_outlined,
                iconColor: AppColors.secondaryColor,
                title: 'Push Notifications',
                subtitle: 'Receive push notifications',
                value: _enablePushNotifications,
                onChanged: (value) {
                  setState(() {
                    _enablePushNotifications = value;
                  });
                },
              ),
              const Divider(height: 1, indent: 76),
              _buildSwitchTile(
                icon: Icons.email_outlined,
                iconColor: AppColors.lightTeal,
                title: 'Email Notifications',
                subtitle: 'Receive updates via email',
                value: _enableEmailNotifications,
                onChanged: (value) {
                  setState(() {
                    _enableEmailNotifications = value;
                  });
                },
              ),
            ]),

            // Notification Categories
            _buildSectionHeader('Notification Categories'),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: Icons.chat_bubble_outline,
                iconColor: AppColors.primaryColor,
                title: 'Messages',
                subtitle: 'Chat and communication updates',
                value: _messagesEnabled,
                onChanged: (value) {
                  setState(() {
                    _messagesEnabled = value;
                  });
                },
              ),
              const Divider(height: 1, indent: 76),
              _buildSwitchTile(
                icon: Icons.home_outlined,
                iconColor: AppColors.secondaryColor,
                title: 'Property Updates',
                subtitle: 'Changes to your saved properties',
                value: _propertyUpdatesEnabled,
                onChanged: (value) {
                  setState(() {
                    _propertyUpdatesEnabled = value;
                  });
                },
              ),
              const Divider(height: 1, indent: 76),
              _buildSwitchTile(
                icon: Icons.calendar_today_outlined,
                iconColor: AppColors.accentColor,
                title: 'Bookings',
                subtitle: 'Viewing appointments and confirmations',
                value: _bookingsEnabled,
                onChanged: (value) {
                  setState(() {
                    _bookingsEnabled = value;
                  });
                },
              ),
              const Divider(height: 1, indent: 76),
              _buildSwitchTile(
                icon: Icons.star_outline,
                iconColor: Colors.amber.shade700,
                title: 'Reviews',
                subtitle: 'Feedback on your properties or services',
                value: _reviewsEnabled,
                onChanged: (value) {
                  setState(() {
                    _reviewsEnabled = value;
                  });
                },
              ),
              const Divider(height: 1, indent: 76),
              _buildSwitchTile(
                icon: Icons.verified_outlined,
                iconColor: Colors.green,
                title: 'Verification',
                subtitle: 'Account and property verification status',
                value: _verificationEnabled,
                onChanged: (value) {
                  setState(() {
                    _verificationEnabled = value;
                  });
                },
              ),
            ]),

            const SizedBox(height: 24),

            // Clear notifications button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showClearNotificationsDialog(context);
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear All Notifications'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(
                      color: Colors.red.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
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

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      secondary: Container(
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
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primaryColor,
    );
  }

  void _showClearNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_outlined,
                color: Colors.red,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Clear All?',
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to clear all notifications? This action cannot be undone.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('All notifications cleared'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: AppColors.primaryColor,
                ),
              );
            },
            child: const Text(
              'Clear All',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}