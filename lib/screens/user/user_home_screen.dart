import 'package:flutter/material.dart';
import 'package:wenest/screens/user/user_search_screen.dart';
import 'package:wenest/screens/user/user_agencies_screen.dart';
import 'package:wenest/screens/user/user_profile_screen.dart';
import 'package:wenest/screens/shared/messages_screen.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/services/supabase_service.dart';
import 'package:wenest/models/property.dart';
import 'package:wenest/models/agency.dart';
import 'package:wenest/models/profile.dart';
import 'package:shimmer/shimmer.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = const <Widget>[
    HomeContent(),
    UserSearchScreen(),
    UserAgenciesScreen(),
    MessagesScreen(),
    UserProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primaryColor,
          unselectedItemColor: Colors.grey.shade400,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded, size: 26),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded, size: 26),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.business_rounded, size: 26),
              label: 'Agencies',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_rounded, size: 26),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded, size: 26),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final _supabaseService = SupabaseService();
  List<Property> _featuredProperties = [];
  List<Agency> _featuredAgencies = [];
  Profile? _profile;
  bool _isLoadingProperties = true;
  bool _isLoadingAgencies = true;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadProfile(),
      _loadFeaturedProperties(),
      _loadFeaturedAgencies(),
    ]);
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoadingProfile = true);
    try {
      final user = _supabaseService.getCurrentUser();
      if (user != null) {
        final profile = await _supabaseService.getProfile(user.id);
        setState(() {
          _profile = profile;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _loadFeaturedProperties() async {
    setState(() => _isLoadingProperties = true);
    try {
      final properties = await _supabaseService.getProperties(
        isFeatured: true,
        limit: 10,
      );
      setState(() {
        _featuredProperties = properties;
        _isLoadingProperties = false;
      });
    } catch (e) {
      setState(() => _isLoadingProperties = false);
    }
  }

  Future<void> _loadFeaturedAgencies() async {
    setState(() => _isLoadingAgencies = true);
    try {
      final agencies = await _supabaseService.getAgencies(
        verified: true,
        limit: 10,
      );
      setState(() {
        _featuredAgencies = agencies;
        _isLoadingAgencies = false;
      });
    } catch (e) {
      setState(() => _isLoadingAgencies = false);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: AppColors.primaryColor,
      child: CustomScrollView(
        slivers: [
          // Header with Profile
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Profile Avatar
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.userProfile);
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryColor.withValues(alpha: 0.2),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryColor.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _isLoadingProfile
                              ? ClipOval(
                                  child: Shimmer.fromColors(
                                    baseColor: Colors.grey.shade300,
                                    highlightColor: Colors.grey.shade100,
                                    child: Container(color: Colors.white),
                                  ),
                                )
                              : CircleAvatar(
                                  backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
                                  backgroundImage: _profile?.avatarUrl != null
                                      ? NetworkImage(_profile!.avatarUrl!)
                                      : null,
                                  child: _profile?.avatarUrl == null
                                      ? Icon(
                                          Icons.person_rounded,
                                          color: AppColors.primaryColor,
                                          size: 26,
                                        )
                                      : null,
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Greeting
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            _isLoadingProfile
                                ? Shimmer.fromColors(
                                    baseColor: Colors.grey.shade300,
                                    highlightColor: Colors.grey.shade100,
                                    child: Container(
                                      height: 20,
                                      width: 120,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  )
                                : Text(
                                    _profile?.fullName ?? 'Welcome!',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ],
                        ),
                      ),
                      // Notification Icon
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.notifications_rounded),
                          color: AppColors.primaryColor,
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.notifications);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Search Widget
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.userSearch);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: Colors.grey.shade400,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Search for properties, location...',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.tune_rounded,
                            color: AppColors.primaryColor,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quick Categories
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Browse Categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildCategoryCard('Apartments', Icons.apartment_rounded, 'For Rent')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildCategoryCard('Houses', Icons.house_rounded, 'For Sale')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildCategoryCard('Land', Icons.landscape_rounded, 'Available')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildCategoryCard('Commercial', Icons.store_rounded, 'For Lease')),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Featured Properties
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Featured Properties',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColor,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.userSearch);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Row(
                            children: [
                              Text('View All', style: TextStyle(fontWeight: FontWeight.w600)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _isLoadingProperties
                      ? _buildPropertiesShimmer()
                      : _featuredProperties.isEmpty
                          ? _buildEmptyState('No featured properties available', Icons.home_work_rounded)
                          : SizedBox(
                              height: 280,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: _featuredProperties.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      right: index < _featuredProperties.length - 1 ? 16 : 0,
                                    ),
                                    child: _buildPropertyCard(_featuredProperties[index]),
                                  );
                                },
                              ),
                            ),
                ],
              ),
            ),
          ),

          // Verified Agencies
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Verified Agencies',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColor,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.userAgencies);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Row(
                            children: [
                              Text('View All', style: TextStyle(fontWeight: FontWeight.w600)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _isLoadingAgencies
                      ? _buildAgenciesShimmer()
                      : _featuredAgencies.isEmpty
                          ? _buildEmptyState('No verified agencies available', Icons.business_rounded)
                          : SizedBox(
                              height: 140,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: _featuredAgencies.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      right: index < _featuredAgencies.length - 1 ? 16 : 0,
                                    ),
                                    child: _buildAgencyCard(_featuredAgencies[index]),
                                  );
                                },
                              ),
                            ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, String subtitle) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.userSearch);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryColor, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyCard(Property property) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/property_detail', arguments: property.id);
      },
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section - UPDATED TO USE REAL IMAGES
            Stack(
              children: [
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: property.primaryImageUrl != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: Image.network(
                            property.primaryImageUrl!,
                            width: double.infinity,
                            height: 160,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  color: AppColors.primaryColor,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.home_rounded,
                                  color: AppColors.primaryColor.withValues(alpha: 0.2),
                                  size: 50,
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.home_rounded,
                            color: AppColors.primaryColor.withValues(alpha: 0.2),
                            size: 50,
                          ),
                        ),
                ),
                if (property.isFeatured)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'FEATURED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_border_rounded,
                      color: AppColors.primaryColor,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            // Details Section (rest stays the same)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.formattedPrice,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    property.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.locationDisplay,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (property.bedrooms != null && property.bedrooms! > 0) ...[
                        Icon(Icons.bed_rounded, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text('${property.bedrooms}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                        const SizedBox(width: 12),
                      ],
                      if (property.bathrooms != null && property.bathrooms! > 0) ...[
                        Icon(Icons.bathtub_rounded, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text('${property.bathrooms}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                        const SizedBox(width: 12),
                      ],
                      if (property.squareMeters != null) ...[
                        Icon(Icons.square_foot_rounded, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text('${property.squareMeters!.toInt()}m²', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildAgencyCard(Agency agency) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/agency_detail', arguments: agency.id);
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(14), // REDUCED from 16 to 14
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //agency logo
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: agency.logoUrl != null
                    ? Image.network(
                        agency.logoUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                              color: AppColors.primaryColor,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.business_rounded,
                            color: AppColors.primaryColor,
                            size: 30,
                          );
                        },
                      )
                    : const Icon(
                        Icons.business_rounded,
                        color: AppColors.primaryColor,
                        size: 30,
                      ),
              ),
            ),
            const SizedBox(height: 10), // REDUCED from 12 to 10
            Text(
              agency.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12, // REDUCED from 13 to 12
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (agency.verified) ...[
              const SizedBox(height: 4), // REDUCED from 6 to 4
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), // REDUCED padding
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 10, color: AppColors.primaryColor), // REDUCED from 12 to 10
                    const SizedBox(width: 3),
                    Text(
                      'Verified',
                      style: TextStyle(
                        fontSize: 9, // REDUCED from 10 to 9
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertiesShimmer() {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: index < 2 ? 16 : 0),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade200,
              highlightColor: Colors.grey.shade50,
              child: Container(
                width: 240,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAgenciesShimmer() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: index < 3 ? 16 : 0),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade200,
              highlightColor: Colors.grey.shade50,
              child: Container(
                width: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}