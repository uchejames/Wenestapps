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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoadingAgency ? 'Loading...' : _agency?.name ?? 'Agency Dashboard'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_rounded),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
          ),
          PopupMenuButton<int>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => <PopupMenuEntry<int>>[
              PopupMenuItem<int>(
                child: ListTile(
                  leading: const Icon(Icons.account_circle, size: 20),
                  title: const Text('Agency Profile'),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _selectedIndex = 5);
                  },
                ),
              ),
              PopupMenuItem<int>(
                child: ListTile(
                  leading: const Icon(Icons.subscriptions, size: 20),
                  title: const Text('Subscription'),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _selectedIndex = 6);
                  },
                ),
              ),
              PopupMenuItem<int>(
                child: ListTile(
                  leading: const Icon(Icons.settings, size: 20),
                  title: const Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.settings);
                  },
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<int>(
                onTap: () => _handleSignOut(),
                child: const ListTile(
                  leading: Icon(Icons.logout, color: Colors.red, size: 20),
                  title: Text('Sign Out', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildBody(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryColor, AppColors.lightTeal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: _agency?.logoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(_agency!.logoUrl!, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.business, size: 30, color: AppColors.primaryColor),
                ),
                const SizedBox(height: 12),
                Text(
                  _agency?.name ?? 'Agency',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'Agency Account',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    if (_agency?.verified == true) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text('Verified', style: TextStyle(color: Colors.white, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          _buildDrawerItem(0, Icons.dashboard_rounded, 'Dashboard'),
          _buildDrawerItem(1, Icons.add_business_rounded, 'Add Property'),
          _buildDrawerItem(2, Icons.house_rounded, 'My Properties'),
          _buildDrawerItem(3, Icons.people_rounded, 'Manage Agents'),
          _buildDrawerItem(4, Icons.analytics_rounded, 'Analytics'),
          const Divider(),
          _buildDrawerItem(5, Icons.account_circle_rounded, 'Agency Profile'),
          _buildDrawerItem(6, Icons.subscriptions_rounded, 'Subscription'),
          _buildDrawerItem(7, Icons.help_rounded, 'Help & Support'),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primaryColor : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppColors.primaryColor : AppColors.textColor,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primaryColor.withValues(alpha: 0.1),
      onTap: () {
        Navigator.pop(context);
        setState(() => _selectedIndex = index);
      },
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
        return AgencyDashboardOverview(agency: _agency!);
      case 1:
        return AddPropertyScreen(agency: _agency!);
      case 2:
        return MyPropertiesScreen(agency: _agency!);
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
        return AgencyDashboardOverview(agency: _agency!);
    }
  }
}

class AgencyDashboardOverview extends StatefulWidget {
  final Agency agency;

  const AgencyDashboardOverview({super.key, required this.agency});

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
      onRefresh: _loadDashboardData,
      color: AppColors.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 24),
              _buildStatsGrid(),
              const SizedBox(height: 32),
              _buildQuickActions(),
              const SizedBox(height: 32),
              _buildRecentProperties(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryColor, AppColors.lightTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back! 👋',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            widget.agency.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Here's what's happening with your properties today",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    if (_isLoading) {
      return GridView.count(
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
      padding: const EdgeInsets.all(14),
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
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
              // Navigate to Add Property by changing the selected index in parent
              final dashboardState = context.findAncestorStateOfType<_AgencyDashboardScreenState>();
              if (dashboardState != null) {
                dashboardState.setState(() => dashboardState._selectedIndex = 1);
              }
            }),
            _buildActionButton('View Messages', Icons.message_rounded, AppColors.secondaryColor, () {
              // Navigate to messages
            }),
            _buildActionButton('Analytics', Icons.analytics_rounded, AppColors.accentColor, () {
              // Navigate to Analytics by changing the selected index in parent
              final dashboardState = context.findAncestorStateOfType<_AgencyDashboardScreenState>();
              if (dashboardState != null) {
                dashboardState.setState(() => dashboardState._selectedIndex = 4);
              }
            }),
            _buildActionButton('Manage Agents', Icons.people_rounded, Colors.grey.shade700, () {
              // Navigate to Manage Agents by changing the selected index in parent
              final dashboardState = context.findAncestorStateOfType<_AgencyDashboardScreenState>();
              if (dashboardState != null) {
                dashboardState.setState(() => dashboardState._selectedIndex = 3);
              }
            }),
          ],
        ),
      ],
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
    return Column(
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
                // Navigate to My Properties by changing the selected index in parent
                final dashboardState = context.findAncestorStateOfType<_AgencyDashboardScreenState>();
                if (dashboardState != null) {
                  dashboardState.setState(() => dashboardState._selectedIndex = 2);
                }
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          Column(
            children: List.generate(3, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildShimmerCard(),
            )),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}