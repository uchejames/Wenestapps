import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/services/supabase_service.dart';
import 'package:wenest/models/property.dart';

class UserSavedPropertiesScreen extends StatefulWidget {
  const UserSavedPropertiesScreen({super.key});

  @override
  State<UserSavedPropertiesScreen> createState() => _UserSavedPropertiesScreenState();
}

class _UserSavedPropertiesScreenState extends State<UserSavedPropertiesScreen> {
  final _supabaseService = SupabaseService();
  final _searchController = TextEditingController();
  
  List<Property> _savedProperties = [];
  List<Property> _filteredProperties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedProperties();
    _searchController.addListener(_filterProperties);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedProperties() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Implement actual saved properties fetching from DB
      // For now, load featured properties as placeholder
      final properties = await _supabaseService.getProperties(
        isFeatured: true,
        limit: 20,
      );

      setState(() {
        _savedProperties = properties;
        _filteredProperties = properties;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading saved properties: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _filterProperties() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProperties = _savedProperties;
      } else {
        _filteredProperties = _savedProperties.where((property) {
          return property.title.toLowerCase().contains(query) ||
                 property.address.toLowerCase().contains(query) ||
                 property.cityArea.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _removeSavedProperty(Property property) async {
    // TODO: Implement actual removal from saved properties
    setState(() {
      _savedProperties.remove(property);
      _filteredProperties.remove(property);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Removed from saved properties'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              setState(() {
                _savedProperties.add(property);
                _filterProperties();
              });
            },
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Saved Properties',
          style: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.primaryColor),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search saved properties...',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 22),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_filteredProperties.length} saved ${_filteredProperties.length == 1 ? 'property' : 'properties'}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Properties List
          Expanded(
            child: _isLoading
                ? _buildShimmerList()
                : _filteredProperties.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: _filteredProperties.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index < _filteredProperties.length - 1 ? 16 : 0,
                            ),
                            child: _buildPropertyCard(_filteredProperties[index]),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(Property property) {
    return Dismissible(
      key: Key(property.id.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => _removeSavedProperty(property),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/property_detail', arguments: property.id);
        },
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Image
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.backgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: Stack(
                  children: [
                    if (property.primaryImageUrl != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                        child: Image.network(
                          property.primaryImageUrl!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.home_rounded,
                                size: 40,
                                color: AppColors.primaryColor.withValues(alpha: 0.3),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      Center(
                        child: Icon(
                          Icons.home_rounded,
                          size: 40,
                          color: AppColors.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                    if (property.isFeatured)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accentColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'FEATURED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Property Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              property.locationDisplay,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        property.formattedPrice,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (property.bedrooms != null && property.bedrooms! > 0) ...[
                            Icon(Icons.bed_rounded, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 3),
                            Text('${property.bedrooms}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                            const SizedBox(width: 10),
                          ],
                          if (property.bathrooms != null && property.bathrooms! > 0) ...[
                            Icon(Icons.bathtub_rounded, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 3),
                            Text('${property.bathrooms}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Remove Icon
              Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  icon: const Icon(Icons.favorite_rounded, color: Colors.red),
                  onPressed: () => _removeSavedProperty(property),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border_rounded, size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text(
            'No saved properties',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Start saving properties to see them here',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.userSearch);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Browse Properties', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade200,
            highlightColor: Colors.grey.shade50,
            child: Container(
              height: 120,
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