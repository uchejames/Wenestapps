import 'package:flutter/material.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/services/supabase_service.dart';
import 'package:wenest/models/agent.dart';
import 'package:wenest/models/property.dart';
import 'package:wenest/models/property_media.dart';
import 'package:shimmer/shimmer.dart';

// Import agent screens
import 'package:wenest/screens/agent/add_property_screen.dart';
import 'package:wenest/screens/agent/my_properties_screen.dart';
import 'package:wenest/screens/agent/my_clients_screen.dart';
import 'package:wenest/screens/agent/agent_profile_screen.dart';
import 'package:wenest/screens/agent/agent_performance_screen.dart';
import 'package:wenest/screens/agent/join_agency_screen.dart';
import 'package:wenest/screens/shared/messages_screen.dart';

class AgentDashboardScreen extends StatefulWidget {
  const AgentDashboardScreen({super.key});

  @override
  State<AgentDashboardScreen> createState() => _AgentDashboardScreenState();
}

class _AgentDashboardScreenState extends State<AgentDashboardScreen> {
  final _supabaseService = SupabaseService();
  int _selectedIndex = 0;
  Agent? _agent;
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Dashboard data
  List<Property> _recentProperties = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadAgentData();
  }

  Future<void> _loadAgentData() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabaseService.getCurrentUser();
      if (user != null) {
        final agent = await _supabaseService.getAgentByProfileId(user.id);
        setState(() {
          _agent = agent;
        });
        
        // Load dashboard data
        await _loadDashboardData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading agent data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadDashboardData() async {
    if (_agent == null) return;
    
    try {
      // Load recent properties
      final properties = await _supabaseService.getProperties(
        agentId: _agent!.id,
        limit: 5,
      );

      // Calculate stats
      final allProperties = await _supabaseService.getProperties(
        agentId: _agent!.id,
        limit: 1000,
      );

      final activeCount = allProperties.where((p) => p.status == 'active').length;
      final totalViews = allProperties.fold<int>(0, (sum, p) => sum + p.viewsCount);
      final totalInquiries = allProperties.fold<int>(0, (sum, p) => sum + p.inquiriesCount);

      setState(() {
        _recentProperties = properties;
        _stats = {
          'total_properties': allProperties.length,
          'active_properties': activeCount,
          'total_views': totalViews,
          'total_inquiries': totalInquiries,
        };
      });
    } catch (e) {
      // Silent fail for dashboard stats
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
          Navigator.pushReplacementNamed(context, '/login');
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_agent == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Agent profile not found', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadAgentData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_rounded),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'settings',
                child: const ListTile(
                  leading: Icon(Icons.settings_rounded, size: 20),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                onTap: () async {
                  await Future.delayed(Duration.zero);
                  if (mounted) {
                    Navigator.pushNamed(context, '/settings');
                  }
                },
              ),
              PopupMenuItem<String>(
                value: 'help',
                child: const ListTile(
                  leading: Icon(Icons.help_rounded, size: 20),
                  title: Text('Help & Support'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                onTap: () async {
                  await Future.delayed(Duration.zero);
                  if (mounted) {
                    Navigator.pushNamed(context, '/help_support');
                  }
                },
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'signout',
                child: const ListTile(
                  leading: Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                  title: Text('Sign Out', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
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
      floatingActionButton: _selectedIndex == 1 ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPropertyScreen(agent: _agent!),
            ),
          ).then((_) => _loadDashboardData());
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ) : null,
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'My Properties';
      case 2:
        return 'Messages';
      case 3:
        return 'My Clients';
      case 4:
        return 'My Profile';
      default:
        return 'Agent Dashboard';
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
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
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: _agent!.avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            _agent!.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person_rounded,
                              size: 35,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.person_rounded,
                          size: 35,
                          color: AppColors.primaryColor,
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  _agent!.fullName ?? 'Agent',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _agent!.email ?? 'No email',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 51),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _agent!.verified ? 'Verified Agent' : 'Pending Verification',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Drawer Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),
                _buildDrawerItem(
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  isSelected: _selectedIndex == 0,
                  onTap: () => _onNavItemTapped(0),
                ),
                _buildDrawerItem(
                  icon: Icons.home_work_rounded,
                  title: 'My Properties',
                  isSelected: _selectedIndex == 1,
                  onTap: () => _onNavItemTapped(1),
                ),
                _buildDrawerItem(
                  icon: Icons.message_rounded,
                  title: 'Messages',
                  isSelected: _selectedIndex == 2,
                  onTap: () => _onNavItemTapped(2),
                ),
                _buildDrawerItem(
                  icon: Icons.people_rounded,
                  title: 'My Clients',
                  isSelected: _selectedIndex == 3,
                  onTap: () => _onNavItemTapped(3),
                ),
                _buildDrawerItem(
                  icon: Icons.person_rounded,
                  title: 'My Profile',
                  isSelected: _selectedIndex == 4,
                  onTap: () => _onNavItemTapped(4),
                ),
                const Divider(height: 32),
                _buildDrawerItem(
                  icon: Icons.analytics_rounded,
                  title: 'Performance',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AgentPerformanceScreen(agent: _agent!),
                      ),
                    );
                  },
                ),
                if (_agent!.agencyId == null)
                  _buildDrawerItem(
                    icon: Icons.business_rounded,
                    title: 'Join Agency',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const JoinAgencyScreen(),
                        ),
                      );
                    },
                  ),
                const Divider(height: 32),
                _buildDrawerItem(
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.help_rounded,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/help_support');
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
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
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

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryColor.withValues(alpha: 25.5) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primaryColor : Colors.grey.shade700,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.primaryColor : Colors.grey.shade800,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildBody() {
    if (_agent == null) {
      return const Center(child: Text('No agent data available'));
    }

    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return MyPropertiesScreen(agent: _agent!);
      case 2:
        return const MessagesScreen();
      case 3:
        return MyClientsScreen(agent: _agent!);
      case 4:
        return AgentProfileScreen(agent: _agent!, onUpdate: _loadAgentData);
      default:
        return _buildDashboard();
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 12.75),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_work_rounded),
            label: 'Properties',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_rounded),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_rounded),
            label: 'Clients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: AppColors.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            _buildStatsGrid(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildRecentProperties(),
            const SizedBox(height: 20),
          ],
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
            color: AppColors.primaryColor.withValues(alpha: 76.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _agent!.fullName ?? 'Agent',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 51),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Manage your properties and grow your real estate business',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 229.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          'Total Properties',
          '${_stats['total_properties'] ?? 0}',
          Icons.home_work_rounded,
          AppColors.primaryColor,
        ),
        _buildStatCard(
          'Active Listings',
          '${_stats['active_properties'] ?? 0}',
          Icons.check_circle_rounded,
          Colors.green,
        ),
        _buildStatCard(
          'Total Views',
          '${_stats['total_views'] ?? 0}',
          Icons.visibility_rounded,
          Colors.blue,
        ),
        _buildStatCard(
          'Inquiries',
          '${_stats['total_inquiries'] ?? 0}',
          Icons.message_rounded,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 10.2),
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
              color: color.withValues(alpha: 25.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
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
                  builder: (context) => AddPropertyScreen(agent: _agent!),
                ),
              ).then((_) => _loadDashboardData());
            }),
            _buildActionButton('View Clients', Icons.people_rounded, AppColors.secondaryColor, () {
              _onNavItemTapped(3);
            }),
            _buildActionButton('Performance', Icons.analytics_rounded, AppColors.accentColor, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AgentPerformanceScreen(agent: _agent!),
                ),
              );
            }),
            _buildActionButton('Messages', Icons.message_rounded, Colors.grey.shade700, () {
              _onNavItemTapped(2);
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
          color: color.withValues(alpha: 25.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 51)),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => _onNavItemTapped(1),
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
    );
  }

  Widget _buildPropertyCard(Property property) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/property_detail', arguments: property.id);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 10.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
              child: property.media.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        property.media.first.mediaUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.home_rounded,
                          color: AppColors.primaryColor,
                          size: 30,
                        ),
                      ),
                    )
                  : const Icon(Icons.home_rounded, color: AppColors.primaryColor, size: 30),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: property.status == 'active'
                              ? Colors.green.withValues(alpha: 25.5)
                              : Colors.grey.withValues(alpha: 25.5),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  property.formattedPrice,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
              ],
            ),
          ],
        ),
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
                    builder: (context) => AddPropertyScreen(agent: _agent!),
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