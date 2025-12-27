import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/services/supabase_service.dart';
import 'package:wenest/models/agent.dart';
import 'package:wenest/models/property.dart';
import 'package:shimmer/shimmer.dart';

class MyPropertiesScreen extends StatefulWidget {
  final Agent agent;

  const MyPropertiesScreen({super.key, required this.agent});

  @override
  State<MyPropertiesScreen> createState() => _MyPropertiesScreenState();
}

class _MyPropertiesScreenState extends State<MyPropertiesScreen> with SingleTickerProviderStateMixin {
  final _supabaseService = SupabaseService();
  late TabController _tabController;
  
  List<Property> _allProperties = [];
  List<Property> _displayedProperties = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadProperties();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      _filterByTab();
    }
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    try {
      final properties = await _supabaseService.getProperties(
        agentId: widget.agent.id,
        limit: 1000,
      );

      setState(() {
        _allProperties = properties;
        _filterByTab();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading properties: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _filterByTab() {
    List<Property> filtered = _allProperties;

    // Filter by tab
    switch (_tabController.index) {
      case 0: // All
        break;
      case 1: // Active
        filtered = filtered.where((p) => p.status == 'active').toList();
        break;
      case 2: // Draft
        filtered = filtered.where((p) => p.status == 'draft').toList();
        break;
      case 3: // Sold/Rented
        filtered = filtered.where((p) => p.status == 'sold' || p.status == 'rented').toList();
        break;
      case 4: // Inactive
        filtered = filtered.where((p) => p.status == 'inactive').toList();
        break;
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               p.cityArea.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               p.state.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Sort by date
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() => _displayedProperties = filtered);
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _filterByTab();
  }

  Future<void> _deleteProperty(Property property) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Property'),
        content: Text('Are you sure you want to delete "${property.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabaseService.deleteProperty(property.id.toString());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Property deleted successfully'), backgroundColor: Colors.green),
          );
          _loadProperties();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting property: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _publishProperty(Property property) async {
    try {
      await _supabaseService.publishProperty(property.id.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Property published successfully'), backgroundColor: Colors.green),
        );
        _loadProperties();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error publishing property: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showPropertyActions(Property property) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.visibility_rounded, color: AppColors.primaryColor),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/property_detail', arguments: property.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: Colors.blue),
              title: const Text('Edit Property'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to edit screen
              },
            ),
            if (property.status == 'draft')
              ListTile(
                leading: const Icon(Icons.publish_rounded, color: Colors.green),
                title: const Text('Publish Property'),
                onTap: () {
                  Navigator.pop(context);
                  _publishProperty(property);
                },
              ),
            if (property.status == 'active')
              ListTile(
                leading: const Icon(Icons.pause_circle_rounded, color: Colors.orange),
                title: const Text('Mark as Inactive'),
                onTap: () {
                  Navigator.pop(context);
                  // Mark as inactive
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: const Text('Delete Property', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteProperty(property);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with Search
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Search Bar
              TextField(
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search properties...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              // Stats Row
              Row(
                children: [
                  Expanded(child: _buildStatChip('Total', _allProperties.length, Icons.home_rounded)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatChip('Active', _allProperties.where((p) => p.status == 'active').length, Icons.check_circle_rounded)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatChip('Draft', _allProperties.where((p) => p.status == 'draft').length, Icons.edit_rounded)),
                ],
              ),
            ],
          ),
        ),
        // Tabs
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primaryColor,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Active'),
              Tab(text: 'Draft'),
              Tab(text: 'Sold/Rented'),
              Tab(text: 'Inactive'),
            ],
          ),
        ),
        // Properties List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadProperties,
            color: AppColors.primaryColor,
            child: _isLoading
                ? _buildShimmerList()
                : _displayedProperties.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _displayedProperties.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildPropertyCard(_displayedProperties[index]),
                          );
                        },
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, int count, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryColor),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(Property property) {
    return GestureDetector(
      onTap: () => _showPropertyActions(property),
      child: Container(
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
          children: [
            // Image Section
            Stack(
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.home_rounded,
                      color: AppColors.primaryColor.withValues(alpha: 0.3),
                      size: 60,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(property.status).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      property.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
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
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
                      ],
                    ),
                    child: const Icon(Icons.more_vert_rounded, size: 18),
                  ),
                ),
              ],
            ),
            // Details Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.locationDisplay,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        property.formattedPrice,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          property.listingTypeDisplay,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPropertyStat(Icons.visibility_rounded, property.viewsCount.toString(), 'Views'),
                      Container(width: 1, height: 20, color: Colors.grey.shade300),
                      _buildPropertyStat(Icons.favorite_rounded, property.savesCount.toString(), 'Saves'),
                      Container(width: 1, height: 20, color: Colors.grey.shade300),
                      _buildPropertyStat(Icons.message_rounded, property.inquiriesCount.toString(), 'Inquiries'),
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

  Widget _buildPropertyStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primaryColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'sold':
      case 'rented':
        return Colors.blue;
      case 'draft':
        return Colors.orange;
      case 'inactive':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_tabController.index) {
      case 1:
        message = 'No active properties';
        icon = Icons.home_work_outlined;
        break;
      case 2:
        message = 'No draft properties';
        icon = Icons.edit_outlined;
        break;
      case 3:
        message = 'No sold/rented properties';
        icon = Icons.check_circle_outlined;
        break;
      case 4:
        message = 'No inactive properties';
        icon = Icons.pause_circle_outlined;
        break;
      default:
        message = 'No properties yet';
        icon = Icons.home_work_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Property'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade200,
            highlightColor: Colors.grey.shade50,
            child: Container(
              height: 320,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }
}