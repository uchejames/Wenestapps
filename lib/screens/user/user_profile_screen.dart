import 'package:flutter/material.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/services/supabase_service.dart';
import 'package:wenest/models/profile.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _supabaseService = SupabaseService();
  
  bool _isEditing = false;
  bool _isLoading = true;
  Profile? _profile;
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

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
    try {
      final user = _supabaseService.getCurrentUser();
      if (user != null) {
        await _supabaseService.updateProfile(
          userId: user.id,
          fullName: _nameController.text,
          phoneNumber: _phoneController.text,
          address: _addressController.text,
          city: _cityController.text,
          state: _stateController.text,
        );

        setState(() => _isEditing = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile updated successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        await _loadProfile();
      }
    } catch (e) {
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

  Future<void> _handleSignOut() async {
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
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
              onPressed: _saveProfile,
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: AppColors.primaryColor),
              onPressed: () {
                setState(() => _isEditing = true);
              },
            ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.primaryColor),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.settings_rounded, color: AppColors.primaryColor),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
                onTap: () {
                  Future.delayed(Duration.zero, () {
                    Navigator.pushNamed(context, AppRoutes.settings);
                  });
                },
              ),
              PopupMenuItem(
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
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
                            child: Text(
                              _getUserTypeDisplay(),
                              style: const TextStyle(
                                color: AppColors.primaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
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
                          _buildProfileField('Full Name', _nameController, _isEditing, Icons.person_rounded),
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

                          const SizedBox(height: 32),
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
                          _buildSettingsOption('Privacy Policy', Icons.privacy_tip_rounded),
                          const SizedBox(height: 12),
                          _buildSettingsOption('Terms of Service', Icons.description_rounded),
                          const SizedBox(height: 12),
                          _buildSettingsOption('Help & Support', Icons.help_rounded),

                          const SizedBox(height: 32),
                          Center(
                            child: OutlinedButton.icon(
                              onPressed: () => _showDeleteAccountDialog(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red, width: 1.5),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.delete_forever_rounded),
                              label: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildProfileField(String label, TextEditingController controller, bool isEditable, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isEditable ? Colors.white : Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade300),
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
                      ),
              ),
            ],
          ),
        ),
      ],
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
            activeColor: AppColors.primaryColor,
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
          title: const Text('Delete Account'),
          content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
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
}