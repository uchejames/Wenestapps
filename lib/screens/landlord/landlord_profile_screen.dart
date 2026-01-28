import 'package:flutter/material.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/services/supabase_service.dart';
import 'package:wenest/models/landlord.dart';
import 'package:wenest/models/profile.dart';
import 'package:shimmer/shimmer.dart';

class LandlordProfileScreen extends StatefulWidget {
  const LandlordProfileScreen({super.key});

  @override
  State<LandlordProfileScreen> createState() => _LandlordProfileScreenState();
}

class _LandlordProfileScreenState extends State<LandlordProfileScreen> {
  final _supabaseService = SupabaseService();
  bool _isLoading = true;
  Profile? _profile;
  Landlord? _landlord;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final user = _supabaseService.getCurrentUser();
      if (user != null) {
        final profile = await _supabaseService.getProfile(user.id);
        final landlord = await _supabaseService.getLandlordByProfileId(user.id);
        
        setState(() {
          _profile = profile;
          _landlord = landlord;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabaseService.signOut();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error signing out: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? _buildLoadingState()
          : CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryColor, AppColors.secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          // Avatar
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              backgroundImage: _profile?.avatarUrl != null
                                  ? NetworkImage(_profile!.avatarUrl!)
                                  : null,
                              child: _profile?.avatarUrl == null
                                  ? const Icon(
                                      Icons.person_rounded,
                                      size: 50,
                                      color: AppColors.primaryColor,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Name
                          Text(
                            _landlord?.companyName ?? _profile?.fullName ?? 'Landlord',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _profile?.email ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Verification Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _landlord?.verified == true
                                  ? Colors.green
                                  : Colors.orange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _landlord?.verified == true
                                      ? Icons.verified_rounded
                                      : Icons.pending_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _landlord?.verified == true ? 'Verified' : 'Pending Verification',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),

                // Profile Info
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profile Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoCard(),
                        const SizedBox(height: 24),
                        const Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsCard(),
                        const SizedBox(height: 24),
                        const Text(
                          'Support',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSupportCard(),
                        const SizedBox(height: 24),
                        _buildSignOutButton(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
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
      child: Column(
        children: [
          _buildInfoItem(
            Icons.business_rounded,
            'Company Name',
            _landlord?.companyName ?? 'Not specified',
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          _buildInfoItem(
            Icons.phone_rounded,
            'Phone',
            _landlord?.phone ?? _profile?.phone ?? 'Not specified',
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          _buildInfoItem(
            Icons.email_rounded,
            'Email',
            _landlord?.email ?? _profile?.email ?? 'Not specified',
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          _buildInfoItem(
            Icons.location_on_rounded,
            'Address',
            _landlord?.address ?? 'Not specified',
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          _buildInfoItem(
            Icons.map_rounded,
            'Location',
            '${_landlord?.city ?? ''}, ${_landlord?.state ?? ''}',
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          _buildInfoItem(
            Icons.home_work_rounded,
            'Properties',
            '${_landlord?.propertiesCount ?? 0}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
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
      child: Column(
        children: [
          _buildSettingsItem(
            Icons.edit_rounded,
            'Edit Profile',
            () {
              // TODO: Navigate to edit profile
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit Profile feature coming soon')),
              );
            },
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          _buildSettingsItem(
            Icons.notifications_rounded,
            'Notifications',
            () {
              Navigator.pushNamed(context, AppRoutes.notificationsSettings);
            },
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          _buildSettingsItem(
            Icons.lock_rounded,
            'Change Password',
            () {
              // TODO: Navigate to change password
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Change Password feature coming soon')),
              );
            },
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          _buildSettingsItem(
            Icons.language_rounded,
            'Language',
            () {
              Navigator.pushNamed(context, AppRoutes.languageSelection);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard() {
    return Container(
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
      child: Column(
        children: [
          _buildSettingsItem(
            Icons.help_rounded,
            'Help & Support',
            () {
              Navigator.pushNamed(context, AppRoutes.helpSupport);
            },
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          _buildSettingsItem(
            Icons.description_rounded,
            'Terms & Conditions',
            () {
              Navigator.pushNamed(context, AppRoutes.termsAndConditions);
            },
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          _buildSettingsItem(
            Icons.privacy_tip_rounded,
            'Privacy Policy',
            () {
              Navigator.pushNamed(context, AppRoutes.privacyPolicy);
            },
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          _buildSettingsItem(
            Icons.info_rounded,
            'About',
            () {
              showAboutDialog(
                context: context,
                applicationName: AppStrings.appName,
                applicationVersion: '1.0.0',
                applicationIcon: Image.asset('assets/images/splash.png', width: 60, height: 60),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _handleSignOut,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.red.shade200),
          ),
        ),
        icon: const Icon(Icons.logout_rounded),
        label: const Text(
          'Sign Out',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            height: 300,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryColor, AppColors.secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.white30,
                    highlightColor: Colors.white60,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Shimmer.fromColors(
                    baseColor: Colors.white30,
                    highlightColor: Colors.white60,
                    child: Container(
                      width: 150,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}