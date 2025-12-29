import 'package:flutter/material.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/services/supabase_service.dart';
import 'package:wenest/models/property.dart';
import 'package:wenest/models/landlord.dart';
import 'package:shimmer/shimmer.dart';

class LandlordPropertiesScreen extends StatefulWidget {
  const LandlordPropertiesScreen({super.key});

  @override
  State<LandlordPropertiesScreen> createState() => _LandlordPropertiesScreenState();
}

class _LandlordPropertiesScreenState extends State<LandlordPropertiesScreen> with SingleTickerProviderStateMixin {
  final _supabaseService = SupabaseService();
  late TabController _tabController;
  
  List<Property> _allProperties = [];
  List<Property> _activeProperties = [];
  List<Property> _rentedProperties = [];
  List<Property> _soldProperties = [];
  List<Property> _draftProperties = [];
  
  Landlord? _landlord;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadProperties();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    
    try {
      final user = _supabaseService.getCurrentUser();
      if (user != null) {
        final landlord = await _supabaseService.getLandlordByProfileId(user.id);
        
        if (landlord != null) {
          final properties = await _supabaseService.getProperties(
            landlordId: landlord.id,
            limit: 100,
          );
          
          setState(() {
            _landlord = landlord;
            _allProperties = properties;
            _activeProperties = properties.where((p) => p.status == 'active').toList();
            _rentedProperties = properties.where((p) => p.status == 'rented').toList();
            _soldProperties = properties.where((p) => p.status == 'sold').toList();
            _draftProperties = properties.where((p) => p.status == 'draft').toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading properties: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshProperties() async {
    await _loadProperties();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Properties',
          style: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.primaryColor),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: AppColors.primaryColor),
            onPressed: () {
              // TODO: Implement filter
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: [
            Tab(text: 'All (${_allProperties.length})'),
            Tab(text: 'Active (${_activeProperties.length})'),
            Tab(text: 'Rented (${_rentedProperties.length})'),
            Tab(text: 'Sold (${_soldProperties.length})'),
            Tab(text: 'Draft (${_draftProperties.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : RefreshIndicator(
              onRefresh: _refreshProperties,
              color: AppColors.primaryColor,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPropertyList(_allProperties),
                  _buildPropertyList(_activeProperties),
                  _buildPropertyList(_rentedProperties),
                  _buildPropertyList(_soldProperties),
                  _buildPropertyList(_draftProperties),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to add property screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add Property feature coming soon')),
          );
        },
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Property'),
      ),
    );
  }

  Widget _buildPropertyList(List<Property> properties) {
    if (properties.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        return _buildPropertyCard(properties[index]);
      },
    );
  }

  Widget _buildPropertyCard(Property property) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                    size: 60,
                    color: AppColors.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: _buildStatusBadge(property.status),
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
                    Icons.more_vert_rounded,
                    size: 20,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        property.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property.locationDisplay,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getListingTypeColor(property.listingType).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        property.listingTypeDisplay,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getListingTypeColor(property.listingType),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (property.bedrooms != null && property.bedrooms! > 0) ...[
                      Icon(Icons.bed_rounded, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text('${property.bedrooms}', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                      const SizedBox(width: 16),
                    ],
                    if (property.bathrooms != null && property.bathrooms! > 0) ...[
                      Icon(Icons.bathtub_rounded, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text('${property.bathrooms}', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                      const SizedBox(width: 16),
                    ],
                    if (property.squareMeters != null) ...[
                      Icon(Icons.square_foot_rounded, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text('${property.squareMeters!.toInt()}m²', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Divider(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(Icons.visibility_rounded, '${property.viewsCount}', 'Views'),
                    _buildStatItem(Icons.favorite_rounded, '${property.savesCount}', 'Saves'),
                    _buildStatItem(Icons.message_rounded, '${property.inquiriesCount}', 'Inquiries'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    
    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        text = 'Active';
        break;
      case 'rented':
        color = Colors.blue;
        text = 'Rented';
        break;
      case 'sold':
        color = Colors.purple;
        text = 'Sold';
        break;
      case 'draft':
        color = Colors.grey;
        text = 'Draft';
        break;
      default:
        color = Colors.orange;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getListingTypeColor(String listingType) {
    switch (listingType.toLowerCase()) {
      case 'sale':
        return Colors.green;
      case 'rent':
        return Colors.blue;
      case 'lease':
        return Colors.orange;
      case 'shortlet':
        return Colors.purple;
      default:
        return AppColors.primaryColor;
    }
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work_outlined, size: 100, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            const Text(
              'No properties yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add your first property to get started',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add Property feature coming soon')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Property'),
            ),
          ],
        ),
      ),
    );
  }
}