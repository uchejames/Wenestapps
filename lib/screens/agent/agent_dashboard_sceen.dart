import 'package:flutter/material.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/services/supabase_service.dart';
import 'package:wenest/models/agent.dart';

class AgentDashboardScreen extends StatefulWidget {
  const AgentDashboardScreen({super.key});

  @override
  State<AgentDashboardScreen> createState() => _AgentDashboardScreenState();
}

class _AgentDashboardScreenState extends State<AgentDashboardScreen> {
  int _selectedIndex = 0;
  Agent? _agentProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAgentProfile();
  }

  Future<void> _loadAgentProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = SupabaseService().getCurrentUser();
      if (user != null) {
        final agent = await SupabaseService().getAgentByProfileId(user.id);
        if (mounted) {
          setState(() {
            _agentProfile = agent;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading agent profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_agentProfile?.isAffiliated == true 
            ? 'Agent Dashboard' 
            : 'Independent Agent'),
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
      drawer: _buildDrawer(),
      body: _buildDashboardContent(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.house),
            label: 'Properties',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Clients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage: _agentProfile?.avatarUrl != null
                      ? NetworkImage(_agentProfile!.avatarUrl!)
                      : null,
                  child: _agentProfile?.avatarUrl == null
                      ? const Icon(Icons.person, size: 30, color: AppColors.primaryColor)
                      : null,
                ),
                const SizedBox(height: 10),
                Text(
                  _agentProfile?.displayTitle ?? 'Agent',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_agentProfile?.agencyName != null) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.business, size: 14, color: Colors.white70),
                      const SizedBox(width: 5),
                      Text(
                        _agentProfile!.agencyName!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 5),
                  const Text(
                    'Independent Agent',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: _selectedIndex == 0,
            onTap: () {
              setState(() => _selectedIndex = 0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.house),
            title: const Text('My Properties'),
            selected: _selectedIndex == 1,
            onTap: () {
              setState(() => _selectedIndex = 1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Clients'),
            selected: _selectedIndex == 2,
            onTap: () {
              setState(() => _selectedIndex = 2);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          if (_agentProfile?.isAffiliated == false) ...[
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Join Agency'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to agency search/join screen
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardOverview();
      case 1:
        return const Center(child: Text('Properties Screen'));
      case 2:
        return const Center(child: Text('Clients Screen'));
      case 3:
        return const Center(child: Text('Profile Screen'));
      default:
        return _buildDashboardOverview();
    }
  }

  Widget _buildDashboardOverview() {
    return RefreshIndicator(
      onRefresh: _loadAgentProfile,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, ${_agentProfile?.displayTitle ?? 'Agent'}!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Here\'s your performance today.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            
            // Stats cards
            Row(
              children: [
                _buildStatCard('Properties', '${_agentProfile?.propertiesCount ?? 0}', Icons.house),
                const SizedBox(width: 16),
                _buildStatCard('Rating', '${_agentProfile?.rating?.toStringAsFixed(1) ?? 'N/A'}', Icons.star),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard('Reviews', '${_agentProfile?.reviewsCount ?? 0}', Icons.rate_review),
                const SizedBox(width: 16),
                _buildStatCard('Experience', '${_agentProfile?.yearsOfExperience ?? 0} yrs', Icons.work),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Verification status
            if (_agentProfile?.verified != true) ...[
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange.shade700),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Your account is pending verification. You\'ll be notified once it\'s approved.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Specializations
            if (_agentProfile?.specialization != null && _agentProfile!.specialization!.isNotEmpty) ...[
              const Text(
                'Your Specializations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _agentProfile!.specialization!.map((spec) {
                  return Chip(
                    label: Text(spec),
                    backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
            ],
            
            // Quick actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildActionCard('Add Property', Icons.add_home, () {}),
                _buildActionCard('View Clients', Icons.people, () {}),
                _buildActionCard('Messages', Icons.message, () {}),
                _buildActionCard('Reports', Icons.analytics, () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
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
                label,
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

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 30,
                color: AppColors.primaryColor,
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
}