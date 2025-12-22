import 'package:flutter/material.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/services/supabase_service.dart';

class AgencyDashboardScreen extends StatefulWidget {
  const AgencyDashboardScreen({super.key});

  @override
  State<AgencyDashboardScreen> createState() => _AgencyDashboardScreenState();
}

class _AgencyDashboardScreenState extends State<AgencyDashboardScreen> {
  int _selectedIndex = 0;
  bool _isLoading = false;

  Future<void> _refreshDashboard() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate network request
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleSignOut() async {
    try {
      await SupabaseService().signOut();
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
        title: const Text('Agency Dashboard'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: _handleSignOut,
                child: const Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.business,
                      size: 30,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Premium Estates Ltd',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Agency Account',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_business),
              title: const Text('Add Property'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.house),
              title: const Text('My Properties'),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Messages'),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Analytics'),
              selected: _selectedIndex == 4,
              onTap: () {
                setState(() {
                  _selectedIndex = 4;
                });
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Agency Profile'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.subscriptions),
              title: const Text('Subscription'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: _buildDashboardContent(),
      ),
    );
  }

  Widget _buildDashboardContent() {
    switch (_selectedIndex) {
      case 0:
        return const AgencyDashboardOverview();
      case 1:
        return const AddPropertyScreen();
      case 2:
        return const MyPropertiesScreen();
      case 3:
        return const AgencyMessagesScreen();
      case 4:
        return const AnalyticsScreen();
      default:
        return const AgencyDashboardOverview();
    }
  }
}

class AgencyDashboardOverview extends StatefulWidget {
  const AgencyDashboardOverview({super.key});

  @override
  State<AgencyDashboardOverview> createState() =>
      _AgencyDashboardOverviewState();
}

class _AgencyDashboardOverviewState extends State<AgencyDashboardOverview> {
  bool _isLoading = false;

  Future<void> _refreshOverview() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate network request
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshOverview,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back, Premium Estates!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Here\'s what\'s happening with your listings today.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              // Stats cards
              Row(
                children: [
                  _buildStatCard('Total Properties', '24', Icons.house),
                  const SizedBox(width: 16),
                  _buildStatCard('Active Listings', '18', Icons.check_circle),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatCard('Views This Month', '1,248', Icons.visibility),
                  const SizedBox(width: 16),
                  _buildStatCard('Messages', '42', Icons.message),
                ],
              ),
              const SizedBox(height: 30),
              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildQuickActionCard(
                    context,
                    'Add New Property',
                    Icons.add,
                    AppColors.primaryColor,
                  ),
                  const SizedBox(width: 16),
                  _buildQuickActionCard(
                    context,
                    'View Messages',
                    Icons.message,
                    AppColors.secondaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildQuickActionCard(
                    context,
                    'View Analytics',
                    Icons.analytics,
                    AppColors.accentColor,
                  ),
                  const SizedBox(width: 16),
                  _buildQuickActionCard(
                    context,
                    'Manage Properties',
                    Icons.edit,
                    Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Recent Properties
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Properties',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to all properties
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildPropertyCard(
                      context,
                      '3 Bedroom Apartment',
                      'Lekki, Lagos',
                      '₦8,000,000',
                      '2 days ago',
                    ),
                    const SizedBox(width: 16),
                    _buildPropertyCard(
                      context,
                      'Office Space',
                      'Victoria Island, Lagos',
                      '₦2,500,000/year',
                      '1 week ago',
                    ),
                    const SizedBox(width: 16),
                    _buildPropertyCard(
                      context,
                      'Duplex',
                      'Ikoyi, Lagos',
                      '₦15,000,000',
                      '2 weeks ago',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primaryColor),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyCard(
    BuildContext context,
    String title,
    String location,
    String price,
    String date,
  ) {
    return Card(
      child: SizedBox(
        width: 250,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.house,
                  size: 40,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                location,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                price,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                date,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddPropertyScreen extends StatelessWidget {
  const AddPropertyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Add Property Screen'),
    );
  }
}

class MyPropertiesScreen extends StatelessWidget {
  const MyPropertiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('My Properties Screen'),
    );
  }
}

class AgencyMessagesScreen extends StatelessWidget {
  const AgencyMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Agency Messages Screen'),
    );
  }
}

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Analytics Screen'),
    );
  }
}
