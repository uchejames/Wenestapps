import 'package:flutter/material.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/services/supabase_service.dart';
import 'package:wenest/models/agency.dart';
import 'package:wenest/models/property.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wenest/screens/shared/help_support_screen.dart';
import 'package:wenest/screens/agency/add_property_screen.dart';
import 'package:wenest/screens/agency/my_properties_screen.dart';
import 'package:wenest/screens/agency/manage_agents_screen.dart';
import 'package:wenest/screens/agency/analytics_screen.dart';
import 'package:wenest/screens/agency/agency_profile_screen.dart';
import 'package:wenest/screens/agency/subscription_screen.dart';
import 'package:wenest/screens/shared/messages_screen.dart';

class AgencyDashboardScreen extends StatefulWidget {
  const AgencyDashboardScreen({super.key});

  @override
  State<AgencyDashboardScreen> createState() => _AgencyDashboardScreenState();
}

class _AgencyDashboardScreenState extends State<AgencyDashboardScreen> {
  final _supabaseService = SupabaseService();
  int _selectedIndex = 0;
  Agency? _agency;
  bool _isLoadingAgency = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadAgencyData();
  }

  Future<void> _loadAgencyData() async {
    setState(() => _isLoadingAgency = true);
    try {
      final user = _supabaseService.getCurrentUser();
      if (user != null) {
        final agency = await _supabaseService.getAgencyByProfileId(user.id);
        setState(() {
          _agency = agency;
          _isLoadingAgency = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingAgency = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading agency data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
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
            ),
          );
        }
      }
    }
  }

  void _onNavItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  String _getAppBarTitle() {
    if (_isLoadingAgency) return 'Loading...';
    
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'My Properties';
      case 2:
        return 'Add Property';
      case 3:
        return 'Manage Agents';
      case 4:
        return 'Analytics';
      case 5:
        return 'Agency Profile';
      case 6:
        return 'Subscription';
      case 7:
        return 'Help & Support';
      default:
        return 'Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_rounded),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'profile',
                child: const ListTile(
                  leading: Icon(Icons.account_circle_rounded, size: 20),
                  title: Text('Agency Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () {
                  Future.delayed(Duration.zero, () {
                    setState(() => _selectedIndex = 5);
                  });
                },
              ),
              PopupMenuItem<String>(
                value: 'subscription',
                child: const ListTile(
                  leading: Icon(Icons.subscriptions_rounded, size: 20),
                  title: Text('Subscription'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () {
                  Future.delayed(Duration.zero, () {
                    setState(() => _selectedIndex = 6);
                  });
                },
              ),
              PopupMenuItem<String>(
                value: 'settings',
                child: const ListTile(
                  leading: Icon(Icons.settings_rounded, size: 20),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () {
                  Future.delayed(Duration.zero, () {
                    Navigator.pushNamed(context, AppRoutes.settings);
                  });
                },
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'signout',
                child: const ListTile(
                  leading: Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                  title: Text('Sign Out', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () {
                  Future.delayed(Duration.zero, () {
                    _handleSignOut();
                  });
                },
              ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryColor, AppColors.lightTeal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: _agency?.logoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(_agency!.logoUrl!, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.business_rounded, size: 35, color: AppColors.primaryColor),
                ),
                const SizedBox(height: 16),
                Text(
                  _agency?.name ?? 'Agency',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Agency Account',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                    if (_agency?.verified == true) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Verified', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Drawer Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(0, Icons.dashboard_rounded, 'Dashboard'),
                _buildDrawerItem(1, Icons.house_rounded, 'My Properties'),
                _buildDrawerItem(2, Icons.add_business_rounded, 'Add Property'),
                _buildDrawerItem(3, Icons.people_rounded, 'Manage Agents'),
                const Divider(height: 1),
                _buildDrawerItem(4, Icons.analytics_rounded, 'Analytics'),
                _buildDrawerItem(5, Icons.account_circle_rounded, 'Agency Profile'),
                _buildDrawerItem(6, Icons.subscriptions_rounded, 'Subscription'),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.settings_rounded, color: Colors.grey),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.settings);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help_rounded, color: Colors.grey),
                  title: const Text('Help & Support'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _selectedIndex = 7);
                  },
                ),
              ],
            ),
          ),
          // Sign Out Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _handleSignOut();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primaryColor : Colors.grey.shade600,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppColors.primaryColor : AppColors.textColor,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primaryColor.withValues(alpha: 0.1),
      onTap: () => _onNavItemTapped(index),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primaryColor,
      unselectedItemColor: Colors.grey.shade600,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      currentIndex: _selectedIndex > 3 ? 0 : _selectedIndex,
      onTap: (index) {
        if (index == 2) {
          // Navigate to Add Property screen
          if (_agency != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddPropertyScreen(agency: _agency!),
              ),
            ).then((_) => _loadAgencyData());
          }
        } else {
          _onNavItemTapped(index);
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.house_rounded),
          label: 'Properties',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_rounded, size: 28),
          label: 'Add',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_rounded),
          label: 'Agents',
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoadingAgency) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_agency == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Agency not found', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAgencyData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    switch (_selectedIndex) {
      case 0:
        return AgencyDashboardOverview(agency: _agency!, onRefresh: _loadAgencyData, onNavigate: (index) => setState(() => _selectedIndex = index));
      case 1:
        return MyPropertiesScreen(agency: _agency!);
      case 2:
        return AddPropertyScreen(agency: _agency!);
      case 3:
        return ManageAgentsScreen(agency: _agency!);
      case 4:
        return AnalyticsScreen(agency: _agency!);
      case 5:
        return AgencyProfileScreen(agency: _agency!, onUpdate: _loadAgencyData);
      case 6:
        return SubscriptionScreen(agency: _agency!);
      case 7:
        return const HelpSupportScreen();
      default:
        return AgencyDashboardOverview(agency: _agency!, onRefresh: _loadAgencyData, onNavigate: (index) => setState(() => _selectedIndex = index));
    }
  }
}

// ============ AGENCY DASHBOARD OVERVIEW ============

class AgencyDashboardOverview extends StatefulWidget {
  final Agency agency;
  final VoidCallback onRefresh;
  final Function(int) onNavigate;

  const AgencyDashboardOverview({
    super.key,
    required this.agency,
    required this.onRefresh,
    required this.onNavigate,
  });

  @override
  State<AgencyDashboardOverview> createState() => _AgencyDashboardOverviewState();
}

class _AgencyDashboardOverviewState extends State<AgencyDashboardOverview> {
  final _supabaseService = SupabaseService();
  List<Property> _recentProperties = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final properties = await _supabaseService.getProperties(
        agencyId: widget.agency.id,
        limit: 5,
      );

      final allProperties = await _supabaseService.getProperties(
        agencyId: widget.agency.id,
        limit: 1000,
      );

      final activeProperties = allProperties.where((p) => p.status == 'active').length;
      final totalViews = allProperties.fold<int>(0, (sum, p) => sum + p.viewsCount);
      final totalInquiries = allProperties.fold<int>(0, (sum, p) => sum + p.inquiriesCount);

      setState(() {
        _recentProperties = properties;
        _stats = {
          'total': allProperties.length,
          'active': activeProperties,
          'views': totalViews,
          'inquiries': totalInquiries,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadDashboardData();
        widget.onRefresh();
      },
      color: AppColors.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            if (widget.agency.verified != true) _buildVerificationAlert(),
            _buildStatsGrid(),
            _buildQuickActions(),
            _buildRecentProperties(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryColor, AppColors.lightTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.agency.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (widget.agency.verified == true)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Here's your property overview today",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationAlert() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: Colors.orange.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your agency is pending verification. You\'ll be notified once approved.',
              style: TextStyle(color: Colors.orange.shade900, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    if (_isLoading) {
      return GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.4,
        children: List.generate(4, (i) => _buildShimmerCard()),
      );
    }

    return GridView.count(
      padding: const EdgeInsets.all(20),
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard('Total Properties', '${_stats['total']}', Icons.house_rounded, AppColors.primaryColor),
        _buildStatCard('Active Listings', '${_stats['active']}', Icons.check_circle_rounded, Colors.green),
        _buildStatCard('Total Views', '${_stats['views']}', Icons.visibility_rounded, Colors.blue),
        _buildStatCard('Inquiries', '${_stats['inquiries']}', Icons.message_rounded, Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _buildActionButton('Add Property', Icons.add_rounded, AppColors.primaryColor, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddPropertyScreen(agency: widget.agency),
                  ),
                ).then((_) => _loadDashboardData());
              }),
              _buildActionButton('Manage Agents', Icons.people_rounded, AppColors.secondaryColor, () {
                widget.onNavigate(3);
              }),
              _buildActionButton('Analytics', Icons.analytics_rounded, AppColors.accentColor, () {
                widget.onNavigate(4);
              }),
              _buildActionButton('Messages', Icons.message_rounded, Colors.grey.shade700, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MessagesScreen(),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentProperties() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Properties',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  widget.onNavigate(1);
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            Column(
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildShimmerCard(),
                ),
              ),
            )
          else if (_recentProperties.isEmpty)
            _buildEmptyState()
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentProperties.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildPropertyCard(_recentProperties[index]),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(Property property) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.home_rounded, color: AppColors.primaryColor, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  property.locationDisplay,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: property.status == 'active'
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        property.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: property.status == 'active' ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.visibility_rounded, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text('${property.viewsCount}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                property.formattedPrice,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.home_work_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No properties yet', style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            Text(
              'Add your first property to get started',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddPropertyScreen(agency: widget.agency),
                  ),
                ).then((_) => _loadDashboardData());
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Property'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}