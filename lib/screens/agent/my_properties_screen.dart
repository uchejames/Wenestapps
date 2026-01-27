import 'package:flutter/material.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/services/supabase_service.dart';
import 'package:wenest/models/agent.dart';
import 'package:wenest/models/property.dart';
import 'package:wenest/models/property_media.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wenest/screens/agent/add_property_screen.dart';
import 'package:wenest/screens/agent/edit_property_screen.dart';

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
  String _sortBy = 'date';

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
      final properties = await _supabaseService.getPropertiesWithMedia(
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

    // Apply sorting
    switch (_sortBy) {
      case 'price_low':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'views':
        filtered.sort((a, b) => b.viewsCount.compareTo(a.viewsCount));
        break;
      case 'date':
      default:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    setState(() => _displayedProperties = filtered);
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _filterByTab();
  }

  void _onSortChanged(String? value) {
    if (value != null) {
      setState(() => _sortBy = value);
      _filterByTab();
    }
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

  Future<void> _togglePropertyStatus(Property property) async {
    try {
      final newStatus = property.status == 'active' ? 'inactive' : 'active';
      await _supabaseService.updateProperty(
        propertyId: property.id.toString(),
        status: newStatus,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Property marked as ${newStatus.toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );
        _loadProperties();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating property: $e'), backgroundColor: Colors.red),
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
            if (property.status == 'draft')
              ListTile(
                leading: const Icon(Icons.publish_rounded, color: Colors.green),
                title: const Text('Publish Property'),
                onTap: () {
                  Navigator.pop(context);
                  _publishProperty(property);
                },
              ),
            if (property.status == 'active' || property.status == 'inactive')
              ListTile(
                leading: Icon(
                  property.status == 'active' ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
                  color: property.status == 'active' ? Colors.orange : Colors.green,
                ),
                title: Text(property.status == 'active' ? 'Mark as Inactive' : 'Mark as Active'),
                onTap: () {
                  Navigator.pop(context);
                  _togglePropertyStatus(property);
                },
              ),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: Colors.blue),
              title: const Text('Edit Property'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditPropertyScreen(
                      agent: widget.agent,
                      property: property,
                    ),
                  ),
                ).then((_) => _loadProperties());
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
        // Header with search and filters
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 12.75),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search properties...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _sortBy,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.sort_rounded),
                      items: const [
                        DropdownMenuItem(value: 'date', child: Text('Date')),
                        DropdownMenuItem(value: 'price_low', child: Text('Price: Low-High')),
                        DropdownMenuItem(value: 'price_high', child: Text('Price: High-Low')),
                        DropdownMenuItem(value: 'views', child: Text('Most Viewed')),
                      ],
                      onChanged: _onSortChanged,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppColors.primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primaryColor,
                tabs: [
                  Tab(text: 'All (${_allProperties.length})'),
                  Tab(text: 'Active (${_allProperties.where((p) => p.status == 'active').length})'),
                  Tab(text: 'Draft (${_allProperties.where((p) => p.status == 'draft').length})'),
                  Tab(text: 'Sold/Rented (${_allProperties.where((p) => p.status == 'sold' || p.status == 'rented').length})'),
                  Tab(text: 'Inactive (${_allProperties.where((p) => p.status == 'inactive').length})'),
                ],
              ),
            ],
          ),
        ),
        
        // Properties List
        Expanded(
          child: _isLoading
              ? _buildShimmerList()
              : _displayedProperties.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadProperties,
                      color: AppColors.primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
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

  Widget _buildPropertyCard(Property property) {
    return InkWell(
      onTap: () => _showPropertyActions(property),
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
          children: [
            // Image Section with status badge
            Stack(
              children: [
                Container(
                  height: 200,
                  decoration: const BoxDecoration(
                    color: AppColors.backgroundColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: property.media.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(
                            property.media.first.mediaUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.home_rounded, size: 60, color: AppColors.primaryColor),
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.home_rounded, size: 60, color: AppColors.primaryColor),
                        ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(property.status),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      property.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (property.isFeatured)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'FEATURED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (property.media.length > 1)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 153),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.image_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${property.media.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddPropertyScreen(agent: widget.agent),
                ),
              ).then((_) => _loadProperties());
            },
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
      padding: const EdgeInsets.all(16),
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