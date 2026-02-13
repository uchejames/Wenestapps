import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      const HomeContent(),
      const UserAgenciesScreen(),
      const UserSearchScreen(),
      const MessagesScreen(),
      const UserProfileScreen(),
    ];
  }

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
              icon: Icon(Icons.business_rounded, size: 26),
              label: 'Agencies',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded, size: 28),
              label: 'Search',
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
  Profile? _profile;
  
  List<Property> _recentlyViewedProperties = [];
  List<Property> _recommendedProperties = [];
  List<Property> _featuredProperties = [];
  List<Property> _recentlyAddedProperties = [];
  List<Agency> _verifiedAgencies = [];
  
  bool _isLoadingProfile = true;
  bool _isLoadingRecentlyViewed = true;
  bool _isLoadingRecommended = true;
  bool _isLoadingFeatured = true;
  bool _isLoadingRecentlyAdded = true;
  bool _isLoadingAgencies = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadProfile(),
      _loadRecentlyViewedProperties(),
      _loadRecommendedProperties(),
      _loadFeaturedProperties(),
      _loadRecentlyAddedProperties(),
      _loadVerifiedAgencies(),
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

  Future<void> _loadRecentlyViewedProperties() async {
    setState(() => _isLoadingRecentlyViewed = true);
    try {
      final user = _supabaseService.getCurrentUser();
      if (user != null) {
        final properties = await _supabaseService.getRecentlyViewedProperties(
          user.id,
          limit: 5,
        );
        setState(() {
          _recentlyViewedProperties = properties;
          _isLoadingRecentlyViewed = false;
        });
      } else {
        setState(() => _isLoadingRecentlyViewed = false);
      }
    } catch (e) {
      setState(() => _isLoadingRecentlyViewed = false);
    }
  }

  Future<void> _loadRecommendedProperties() async {
    setState(() => _isLoadingRecommended = true);
    try {
      final user = _supabaseService.getCurrentUser();
      if (user != null) {
        final properties = await _supabaseService.getRecommendedProperties(
          user.id,
          limit: 10,
        );
        setState(() {
          _recommendedProperties = properties;
          _isLoadingRecommended = false;
        });
      } else {
        setState(() => _isLoadingRecommended = false);
      }
    } catch (e) {
      setState(() => _isLoadingRecommended = false);
    }
  }

  Future<void> _loadFeaturedProperties() async {
    setState(() => _isLoadingFeatured = true);
    try {
      final properties = await _supabaseService.getProperties(
        isFeatured: true,
        limit: 10,
      );
      setState(() {
        _featuredProperties = properties;
        _isLoadingFeatured = false;
      });
    } catch (e) {
      setState(() => _isLoadingFeatured = false);
    }
  }

  Future<void> _loadRecentlyAddedProperties() async {
    setState(() => _isLoadingRecentlyAdded = true);
    try {
      final properties = await _supabaseService.getRecentlyAddedProperties(limit: 10);
      setState(() {
        _recentlyAddedProperties = properties;
        _isLoadingRecentlyAdded = false;
      });
    } catch (e) {
      setState(() => _isLoadingRecentlyAdded = false);
    }
  }

  Future<void> _loadVerifiedAgencies() async {
    setState(() => _isLoadingAgencies = true);
    try {
      final agencies = await _supabaseService.getAgencies(
        verified: true,
        limit: 10,
      );
      setState(() {
        _verifiedAgencies = agencies;
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

  void _navigateToSearchWithFilter({
    String? listingType,
    String? propertyType,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserSearchScreen(
          initialFilters: {
            if (listingType != null) 'listingType': listingType,
            if (propertyType != null) 'propertyType': propertyType,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: AppColors.primaryColor,
      child: CustomScrollView(
        slivers: [
          // Clean White Header
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row
                  Row(
                    children: [
                      // Profile Avatar
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.userProfile),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryColor.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                          child: _isLoadingProfile
                              ? ClipOval(
                                  child: Shimmer.fromColors(
                                    baseColor: Colors.grey.shade200,
                                    highlightColor: Colors.grey.shade50,
                                    child: Container(color: Colors.white),
                                  ),
                                )
                              : CircleAvatar(
                                  backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
                                  backgroundImage: _profile?.avatarUrl != null
                                      ? CachedNetworkImageProvider(_profile!.avatarUrl!)
                                      : null,
                                  child: _profile?.avatarUrl == null
                                      ? Text(
                                          _profile?.initials ?? 'U',
                                          style: const TextStyle(
                                            color: AppColors.primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        )
                                      : null,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Greeting
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            _isLoadingProfile
                                ? Shimmer.fromColors(
                                    baseColor: Colors.grey.shade200,
                                    highlightColor: Colors.grey.shade50,
                                    child: Container(
                                      width: 120,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  )
                                : Text(
                                    _profile?.displayName ?? 'Welcome',
                                    style: const TextStyle(
                                      color: AppColors.textColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ],
                        ),
                      ),
                      // Saved Properties Button
                      IconButton(
                        onPressed: () => Navigator.pushNamed(context, '/user_saved_properties'),
                        icon: const Icon(Icons.bookmark_rounded),
                        color: AppColors.primaryColor,
                        iconSize: 26,
                      ),
                      // Notifications Button
                      IconButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
                        icon: const Icon(Icons.notifications_outlined),
                        color: AppColors.primaryColor,
                        iconSize: 26,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Search Bar
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.userSearch),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Search for properties...',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Continue Searching
          if (_recentlyViewedProperties.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildSection(
                title: 'Continue Searching',
                subtitle: 'Pick up where you left off',
                icon: Icons.history_rounded,
                child: _isLoadingRecentlyViewed
                    ? _buildPropertiesShimmer()
                    : SizedBox(
                        height: 280,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _recentlyViewedProperties.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(
                                right: index < _recentlyViewedProperties.length - 1 ? 16 : 0,
                              ),
                              child: _buildPropertyCard(_recentlyViewedProperties[index]),
                            );
                          },
                        ),
                      ),
              ),
            ),

          // What are you looking for?
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.explore_rounded,
                          size: 20,
                          color: AppColors.accentColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'What are you looking for?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.5,
                    children: [
                      _buildGoalCard(
                        'Buy Land',
                        Icons.landscape_rounded,
                        () => _navigateToSearchWithFilter(listingType: 'sale', propertyType: 'land'),
                      ),
                      _buildGoalCard(
                        'Rent Apartment',
                        Icons.apartment_rounded,
                        () => _navigateToSearchWithFilter(listingType: 'rent', propertyType: 'apartment'),
                      ),
                      _buildGoalCard(
                        'Buy House',
                        Icons.house_rounded,
                        () => _navigateToSearchWithFilter(listingType: 'sale', propertyType: 'house'),
                      ),
                      _buildGoalCard(
                        'Rent Office',
                        Icons.business_center_rounded,
                        () => _navigateToSearchWithFilter(listingType: 'rent', propertyType: 'office'),
                      ),
                      _buildGoalCard(
                        'Shortlet',
                        Icons.weekend_rounded,
                        () => _navigateToSearchWithFilter(listingType: 'shortlet'),
                      ),
                      _buildGoalCard(
                        'Family Homes',
                        Icons.family_restroom_rounded,
                        () => _navigateToSearchWithFilter(propertyType: 'house'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Recommended For You
          if (_recommendedProperties.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildSection(
                title: 'Recommended For You',
                subtitle: 'Based on your preferences',
                icon: Icons.auto_awesome_rounded,
                child: _isLoadingRecommended
                    ? _buildPropertiesShimmer()
                    : SizedBox(
                        height: 280,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _recommendedProperties.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(
                                right: index < _recommendedProperties.length - 1 ? 16 : 0,
                              ),
                              child: _buildPropertyCard(_recommendedProperties[index]),
                            );
                          },
                        ),
                      ),
              ),
            ),

          // Featured Properties
          SliverToBoxAdapter(
            child: _buildSection(
              title: 'Featured Properties',
              subtitle: 'Premium listings',
              icon: Icons.star_rounded,
              child: _isLoadingFeatured
                  ? _buildPropertiesShimmer()
                  : _featuredProperties.isEmpty
                      ? _buildEmptyState('No featured properties available', Icons.star_border_rounded)
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
            ),
          ),

          // Just Listed
          if (_recentlyAddedProperties.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildSection(
                title: 'Just Listed',
                subtitle: 'Fresh this week',
                icon: Icons.new_releases_rounded,
                child: _isLoadingRecentlyAdded
                    ? _buildPropertiesShimmer()
                    : SizedBox(
                        height: 280,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _recentlyAddedProperties.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(
                                right: index < _recentlyAddedProperties.length - 1 ? 16 : 0,
                              ),
                              child: _buildPropertyCard(_recentlyAddedProperties[index]),
                            );
                          },
                        ),
                      ),
              ),
            ),

          // Market Insights
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.secondaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.secondaryColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.trending_up_rounded,
                          color: AppColors.secondaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Market Insights',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInsightItem(
                    'Lekki rent increased 8% this month',
                    'High demand area',
                    Icons.arrow_upward_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildInsightItem(
                    'Ajah average: ₦2.4M/year',
                    'Affordable zone',
                    Icons.payments_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildInsightItem(
                    'Ikorodu developments up 15%',
                    'Emerging market',
                    Icons.location_city_rounded,
                  ),
                ],
              ),
            ),
          ),

          // Trusted Agencies
          SliverToBoxAdapter(
            child: _buildSection(
              title: 'Trusted Agencies',
              subtitle: 'Verified partners',
              icon: Icons.verified_rounded,
              child: _isLoadingAgencies
                  ? _buildAgenciesShimmer()
                  : _verifiedAgencies.isEmpty
                      ? _buildEmptyState('No agencies available', Icons.business_rounded)
                      : SizedBox(
                          height: 140,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _verifiedAgencies.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: index < _verifiedAgencies.length - 1 ? 16 : 0,
                                ),
                                child: _buildAgencyCard(_verifiedAgencies[index]),
                              );
                            },
                          ),
                        ),
            ),
          ),

          // Property Guide
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: AppColors.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Property Guide',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildGuideTile(
                    'First time renting guide',
                    'Everything you need to know',
                    Icons.menu_book_rounded,
                    () => Navigator.pushNamed(context, AppRoutes.helpSupport),
                  ),
                  const Divider(height: 24),
                  _buildGuideTile(
                    'Avoiding scams',
                    'Red flags to watch out for',
                    Icons.warning_amber_rounded,
                    () => Navigator.pushNamed(context, AppRoutes.faq),
                  ),
                  const Divider(height: 24),
                  _buildGuideTile(
                    'Document checklist',
                    'Essential paperwork',
                    Icons.checklist_rounded,
                    () => Navigator.pushNamed(context, AppRoutes.helpSupport),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildGoalCard(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.primaryColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.secondaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: AppColors.secondaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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
      ],
    );
  }

  Widget _buildGuideTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: Colors.grey.shade400,
          ),
        ],
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
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  property.primaryImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: property.primaryImageUrl!,
                          width: 240,
                          height: 140,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade200,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.home_rounded,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          width: 240,
                          height: 140,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.home_rounded,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                  if (property.isFeatured)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Featured',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        property.listingTypeDisplay,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
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
                      Icon(Icons.location_on_rounded, size: 14, color: Colors.grey.shade600),
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
        padding: const EdgeInsets.all(14),
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
                    ? CachedNetworkImage(
                        imageUrl: agency.logoUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        errorWidget: (context, error, stackTrace) {
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
            const SizedBox(height: 10),
            Text(
              agency.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (agency.verified) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 10, color: AppColors.primaryColor),
                    SizedBox(width: 3),
                    Text(
                      'Verified',
                      style: TextStyle(
                        fontSize: 9,
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