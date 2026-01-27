import 'package:flutter/material.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/services/supabase_service.dart';
import 'package:wenest/models/profile.dart';
import 'package:shimmer/shimmer.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _supabaseService = SupabaseService();
  
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;
  Profile? _profile;
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _bioController = TextEditingController();

  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _pushNotifications = true;

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
        setState(() {
          _profile = profile;
          _nameController.text = profile?.fullName ?? '';
          _emailController.text = profile?.email ?? user.email ?? '';
          _phoneController.text = profile?.phone ?? '';
          _addressController.text = profile?.address ?? '';
          _cityController.text = profile?.city ?? '';
          _stateController.text = profile?.state ?? '';
          _bioController.text = profile?.bio ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _refreshProfile() async {
    await _loadProfile();
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your name'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = _supabaseService.getCurrentUser();
      if (user != null) {
        await _supabaseService.updateProfile(
          userId: user.id,
          fullName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
          state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
          bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        );

        setState(() {
          _isEditing = false;
          _isSaving = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Profile updated successfully'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        await _loadProfile();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      // Reset controllers to original values
      _nameController.text = _profile?.fullName ?? '';
      _phoneController.text = _profile?.phone ?? '';
      _addressController.text = _profile?.address ?? '';
      _cityController.text = _profile?.city ?? '';
      _stateController.text = _profile?.state ?? '';
      _bioController.text = _profile?.bio ?? '';
    });
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabaseService.signOut();
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: ${error.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _isSaving ? null : _cancelEditing,
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: AppColors.primaryColor),
              onPressed: () {
                setState(() => _isEditing = true);
              },
            ),
          if (_isEditing)
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.primaryColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'settings',
                  child: const Row(
                    children: [
                      Icon(Icons.settings_rounded, color: AppColors.primaryColor),
                      SizedBox(width: 12),
                      Text('Settings'),
                    ],
                  ),
                  onTap: () {
                    if (mounted) {
                      Future.delayed(Duration.zero, () {
                        Navigator.pushNamed(context, AppRoutes.settings);
                      });
                    }
                  },
                ),
                PopupMenuItem<String>(
                  value: 'help',
                  child: const Row(
                    children: [
                      Icon(Icons.help_rounded, color: AppColors.primaryColor),
                      SizedBox(width: 12),
                      Text('Help & Support'),
                    ],
                  ),
                  onTap: () {
                    if (mounted) {
                      Future.delayed(Duration.zero, () {
                        Navigator.pushNamed(context, AppRoutes.helpSupport);
                      });
                    }
                  },
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'signout',
                  child: const Row(
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Sign Out', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  onTap: () {
                    Future.delayed(Duration.zero, _handleSignOut);
                  },
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? _buildShimmerLoading()
          : RefreshIndicator(
              onRefresh: _refreshProfile,
              color: AppColors.primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Profile Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primaryColor.withValues(alpha: 0.2),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
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
                              if (_isEditing)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Image upload coming soon'),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 3),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _profile?.fullName ?? 'User',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getUserTypeIcon(),
                                  size: 14,
                                  color: AppColors.primaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getUserTypeDisplay(),
                                  style: const TextStyle(
                                    color: AppColors.primaryColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_profile?.isVerified == true) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_rounded, size: 16, color: Colors.green.shade700),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Verified Account',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Profile Details
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildProfileField('Full Name', _nameController, _isEditing, Icons.person_rounded, isRequired: true),
                          const SizedBox(height: 16),
                          _buildProfileField('Email Address', _emailController, false, Icons.email_rounded),
                          const SizedBox(height: 16),
                          _buildProfileField('Phone Number', _phoneController, _isEditing, Icons.phone_rounded),
                          const SizedBox(height: 16),
                          _buildProfileField('Address', _addressController, _isEditing, Icons.home_rounded),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildProfileField('City', _cityController, _isEditing, Icons.location_city_rounded)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildProfileField('State', _stateController, _isEditing, Icons.map_rounded)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildProfileField('Bio', _bioController, _isEditing, Icons.info_rounded, maxLines: 3),

                          const SizedBox(height: 32),

                          // My Activity Section
                          const Text(
                            'My Activity',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildActivityOption('Saved Properties', Icons.favorite_rounded, '12', onTap: () {
                            Navigator.pushNamed(context, '/user_saved_properties');
                          }),
                          const SizedBox(height: 12),
                          _buildActivityOption('Viewing History', Icons.history_rounded, '45'),
                          const SizedBox(height: 12),
                          _buildActivityOption('My Inquiries', Icons.question_answer_rounded, '8'),

                          const SizedBox(height: 32),

                          // Preferences
                          const Text(
                            'Preferences',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildPreferenceOption('Email Notifications', _emailNotifications, (value) {
                            setState(() => _emailNotifications = value);
                          }),
                          const SizedBox(height: 12),
                          _buildPreferenceOption('SMS Notifications', _smsNotifications, (value) {
                            setState(() => _smsNotifications = value);
                          }),
                          const SizedBox(height: 12),
                          _buildPreferenceOption('Push Notifications', _pushNotifications, (value) {
                            setState(() => _pushNotifications = value);
                          }),

                          const SizedBox(height: 32),

                          // Account Settings
                          const Text(
                            'Account Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSettingsOption('Change Password', Icons.lock_rounded),
                          const SizedBox(height: 12),
                          _buildSettingsOption('Privacy & Security', Icons.security_rounded),
                          const SizedBox(height: 12),
                          _buildSettingsOption('Privacy Policy', Icons.privacy_tip_rounded),
                          const SizedBox(height: 12),
                          _buildSettingsOption('Terms of Service', Icons.description_rounded),

                          const SizedBox(height: 32),

                          // Danger Zone
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.warning_rounded, color: Colors.red.shade700, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Danger Zone',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _showDeleteAccountDialog,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red, width: 1.5),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: const Icon(Icons.delete_forever_rounded),
                                    label: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _getUserTypeDisplay() {
    switch (_profile?.userType?.toLowerCase()) {
      case 'agent':
        return 'Real Estate Agent';
      case 'agency':
        return 'Agency';
      case 'landlord':
        return 'Property Owner';
      default:
        return 'User';
    }
  }

  IconData _getUserTypeIcon() {
    switch (_profile?.userType?.toLowerCase()) {
      case 'agent':
        return Icons.badge_rounded;
      case 'agency':
        return Icons.business_rounded;
      case 'landlord':
        return Icons.apartment_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  Widget _buildProfileField(
    String label,
    TextEditingController controller,
    bool isEditable,
    IconData icon, {
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text('*', style: TextStyle(color: Colors.red, fontSize: 13)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isEditable ? Colors.white : Colors.grey.shade50,
            border: Border.all(
              color: isEditable ? AppColors.primaryColor.withValues(alpha: 0.3) : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: isEditable
                    ? TextField(
                        controller: controller,
                        maxLines: maxLines,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontSize: 15),
                      )
                    : Text(
                        controller.text.isEmpty ? 'Not provided' : controller.text,
                        style: TextStyle(
                          fontSize: 15,
                          color: controller.text.isEmpty ? Colors.grey : AppColors.textColor,
                        ),
                        maxLines: maxLines,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityOption(String label, IconData icon, String count, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label coming soon'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceOption(String label, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOption(String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label coming soon'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.red.shade700),
              const SizedBox(width: 12),
              const Text('Delete Account'),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Account deletion coming soon'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade200,
                  highlightColor: Colors.grey.shade50,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade200,
                  highlightColor: Colors.grey.shade50,
                  child: Container(
                    height: 24,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade200,
                  highlightColor: Colors.grey.shade50,
                  child: Container(
                    height: 20,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade200,
                  highlightColor: Colors.grey.shade50,
                  child: Container(
                    height: 18,
                    width: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(6, (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey.shade200,
                    highlightColor: Colors.grey.shade50,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}