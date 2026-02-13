import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/utils/nigerian_locations.dart';
import 'package:wenest/services/supabase_service.dart';
import 'package:wenest/models/property.dart';

class UserSearchScreen extends StatefulWidget {
  final Map<String, dynamic>? initialFilters;
  
  const UserSearchScreen({super.key, this.initialFilters});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _supabaseService = SupabaseService();
  final _searchController = TextEditingController();

  List<Property> _properties = [];
  List<Property> _filteredProperties = [];
  bool _isLoading = true;

  // Filter variables
  String? _selectedPropertyType;
  String? _selectedListingType;
  String? _selectedState;
  String? _selectedCity;
  String? _selectedFurnishing;
  double _minPrice = 0;
  double _maxPrice = 100000000;
  int? _minBedrooms;
  int? _maxBedrooms;
  int? _minBathrooms;
  bool? _negotiableOnly;
  bool? _featuredOnly;
  bool? _verifiedOnly;

  final List<Map<String, dynamic>> _quickFilters = [
    {'label': 'Rent', 'type': 'listing', 'value': 'rent', 'icon': Icons.key_rounded},
    {'label': 'Buy', 'type': 'listing', 'value': 'sale', 'icon': Icons.home_rounded},
    {'label': 'Shortlet', 'type': 'listing', 'value': 'shortlet', 'icon': Icons.weekend_rounded},
    {'label': 'Land', 'type': 'property', 'value': 'land', 'icon': Icons.landscape_rounded},
    {'label': 'Apartment', 'type': 'property', 'value': 'apartment', 'icon': Icons.apartment_rounded},
    {'label': 'House', 'type': 'property', 'value': 'house', 'icon': Icons.house_rounded},
    {'label': 'Commercial', 'type': 'property', 'value': 'commercial', 'icon': Icons.business_rounded},
  ];

  final List<String> _propertyTypes = [
    'apartment',
    'house',
    'condo',
    'land',
    'commercial',
    'office',
    'warehouse',
  ];

  final List<String> _listingTypes = [
    'sale',
    'rent',
    'lease',
    'shortlet',
  ];

  final List<String> _furnishingOptions = [
    'unfurnished',
    'semi-furnished',
    'fully-furnished',
  ];

  @override
  void initState() {
    super.initState();
    
    // Apply initial filters if provided
    if (widget.initialFilters != null) {
      _selectedListingType = widget.initialFilters!['listingType'];
      _selectedPropertyType = widget.initialFilters!['propertyType'];
    }
    
    _loadProperties();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final properties = await _supabaseService.getProperties(
        propertyType: _selectedPropertyType,
        listingType: _selectedListingType,
        state: _selectedState,
        cityArea: _selectedCity,
        minPrice: _minPrice > 0 ? _minPrice : null,
        maxPrice: _maxPrice < 100000000 ? _maxPrice : null,
        minBedrooms: _minBedrooms,
        maxBedrooms: _maxBedrooms,
        isFeatured: _featuredOnly,
        limit: 100,
      );

      setState(() {
        _properties = properties;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading properties: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    List<Property> filtered = List.from(_properties);

    // Text search
    if (_searchController.text.isNotEmpty) {
      final searchText = _searchController.text.toLowerCase();
      filtered = filtered.where((property) {
        return property.title.toLowerCase().contains(searchText) ||
            property.address.toLowerCase().contains(searchText) ||
            property.cityArea.toLowerCase().contains(searchText) ||
            property.state.toLowerCase().contains(searchText);
      }).toList();
    }

    // Furnishing
    if (_selectedFurnishing != null) {
      filtered = filtered
          .where((p) => p.furnishingStatus == _selectedFurnishing)
          .toList();
    }

    // Minimum bathrooms
    if (_minBathrooms != null) {
      filtered = filtered
          .where((p) => (p.bathrooms ?? 0) >= _minBathrooms!)
          .toList();
    }

    // Negotiable only
    if (_negotiableOnly == true) {
      filtered = filtered.where((p) => p.negotiable).toList();
    }

    // Verified only
    if (_verifiedOnly == true) {
      filtered = filtered.where((p) => p.isVerified).toList();
    }

    setState(() {
      _filteredProperties = filtered;
    });
  }

  Future<void> _refreshProperties() async {
    await _loadProperties();
  }

  void _clearFilters() {
    setState(() {
      _selectedPropertyType = null;
      _selectedListingType = null;
      _selectedState = null;
      _selectedCity = null;
      _selectedFurnishing = null;
      _minPrice = 0;
      _maxPrice = 100000000;
      _minBedrooms = null;
      _maxBedrooms = null;
      _minBathrooms = null;
      _negotiableOnly = null;
      _featuredOnly = null;
      _verifiedOnly = null;
      _searchController.clear();
    });
    _loadProperties();
  }

  void _applyQuickFilter(Map<String, dynamic> filter) {
    setState(() {
      if (filter['type'] == 'listing') {
        if (_selectedListingType == filter['value']) {
          _selectedListingType = null;
        } else {
          _selectedListingType = filter['value'];
        }
      } else if (filter['type'] == 'property') {
        if (_selectedPropertyType == filter['value']) {
          _selectedPropertyType = null;
        } else {
          _selectedPropertyType = filter['value'];
        }
      }
    });
    _loadProperties();
  }

  int _getActiveFiltersCount() {
    int count = 0;
    if (_selectedPropertyType != null) count++;
    if (_selectedListingType != null) count++;
    if (_selectedState != null) count++;
    if (_selectedCity != null) count++;
    if (_selectedFurnishing != null) count++;
    if (_minPrice > 0 || _maxPrice < 100000000) count++;
    if (_minBedrooms != null || _maxBedrooms != null) count++;
    if (_minBathrooms != null) count++;
    if (_negotiableOnly == true) count++;
    if (_featuredOnly == true) count++;
    if (_verifiedOnly == true) count++;
    return count;
  }

  String _formatText(String text) {
    return text.split('-').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Search Properties',
          style: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.primaryColor),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProperties,
        color: AppColors.primaryColor,
        child: Column(
          children: [
            // Search Bar + Filter Button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search location, property...',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () => _searchController.clear(),
                              child: Icon(Icons.clear, color: Colors.grey.shade400, size: 20),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _showFilterSheet,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Badge(
                        isLabelVisible: _getActiveFiltersCount() > 0,
                        label: Text('${_getActiveFiltersCount()}'),
                        backgroundColor: AppColors.accentColor,
                        child: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Quick Filter Buttons
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: _quickFilters.map((filter) {
                    final bool isActive = (filter['type'] == 'listing' && 
                                           _selectedListingType == filter['value']) ||
                                          (filter['type'] == 'property' && 
                                           _selectedPropertyType == filter['value']);
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _applyQuickFilter(filter),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive 
                                ? AppColors.primaryColor 
                                : AppColors.backgroundColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive 
                                  ? AppColors.primaryColor 
                                  : Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                filter['icon'] as IconData,
                                size: 16,
                                color: isActive ? Colors.white : AppColors.textColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                filter['label'] as String,
                                style: TextStyle(
                                  color: isActive ? Colors.white : AppColors.textColor,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Results Count
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: AppColors.backgroundColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_filteredProperties.length} properties found',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  if (_getActiveFiltersCount() > 0)
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear filters'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                ],
              ),
            ),

            // Properties Grid
            Expanded(
              child: _isLoading
                  ? _buildLoadingGrid()
                  : _filteredProperties.isEmpty
                      ? _buildEmptyState()
                      : GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.68,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _filteredProperties.length,
                          itemBuilder: (context, index) {
                            return _buildPropertyGridCard(_filteredProperties[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyGridCard(Property property) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/property_detail', arguments: property.id);
      },
      child: Container(
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
            // Property Image
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  children: [
                    property.primaryImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: property.primaryImageUrl!,
                            width: double.infinity,
                            height: double.infinity,
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
                                size: 30,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(
                                Icons.home_rounded,
                                size: 30,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                    // Listing Type Badge
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
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // Featured Badge
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
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 10, color: Colors.white),
                              SizedBox(width: 3),
                              Text(
                                'Featured',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
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
            // Property Details
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.formattedPrice,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          property.title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 12, color: Colors.grey.shade600),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                property.locationDisplay,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (property.bedrooms != null && property.bedrooms! > 0) ...[
                          Icon(Icons.bed_rounded, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 3),
                          Text('${property.bedrooms}', 
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                          const SizedBox(width: 8),
                        ],
                        if (property.bathrooms != null && property.bathrooms! > 0) ...[
                          Icon(Icons.bathtub_rounded, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 3),
                          Text('${property.bathrooms}', 
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.grey.shade50,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No properties found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Clear Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // CONTINUE IN PART 2...

// Add these methods to the _UserSearchScreenState class

void _showFilterSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _selectedPropertyType = null;
                                _selectedListingType = null;
                                _selectedState = null;
                                _selectedCity = null;
                                _selectedFurnishing = null;
                                _minPrice = 0;
                                _maxPrice = 100000000;
                                _minBedrooms = null;
                                _maxBedrooms = null;
                                _minBathrooms = null;
                                _negotiableOnly = null;
                                _featuredOnly = null;
                                _verifiedOnly = null;
                              });
                            },
                            child: const Text('Clear All'),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Filter Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Property Type
                        _buildFilterSection(
                          'Property Type',
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _propertyTypes.map((type) {
                              return _buildSelectableChip(
                                _formatText(type),
                                _selectedPropertyType == type,
                                () {
                                  setModalState(() {
                                    _selectedPropertyType =
                                        _selectedPropertyType == type ? null : type;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Listing Type
                        _buildFilterSection(
                          'Listing Type',
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _listingTypes.map((type) {
                              return _buildSelectableChip(
                                _formatText(type),
                                _selectedListingType == type,
                                () {
                                  setModalState(() {
                                    _selectedListingType =
                                        _selectedListingType == type ? null : type;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Location - State
                        _buildFilterSection(
                          'State',
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                value: _selectedState,
                                isExpanded: true,
                                hint: const Text('Select State'),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('All States'),
                                  ),
                                  ...NigerianLocations.getAllStates().map((state) {
                                    return DropdownMenuItem<String?>(
                                      value: state,
                                      child: Text(state),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setModalState(() {
                                    _selectedState = value;
                                    _selectedCity = null; // Reset city when state changes
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Location - City
                        if (_selectedState != null)
                          _buildFilterSection(
                            'City/Area',
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  value: _selectedCity,
                                  isExpanded: true,
                                  hint: const Text('Select City/Area'),
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('All Cities'),
                                    ),
                                    ...NigerianLocations.getCitiesForState(_selectedState!)
                                        .map((city) {
                                      return DropdownMenuItem<String?>(
                                        value: city,
                                        child: Text(city),
                                      );
                                    }),
                                  ],
                                  onChanged: (value) {
                                    setModalState(() {
                                      _selectedCity = value;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        
                        // Price Range
                        _buildFilterSection(
                          'Price Range (₦)',
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      decoration: InputDecoration(
                                        labelText: 'Min Price',
                                        hintText: '0',
                                        filled: true,
                                        fillColor: AppColors.backgroundColor,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        setModalState(() {
                                          _minPrice = double.tryParse(value) ?? 0;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      decoration: InputDecoration(
                                        labelText: 'Max Price',
                                        hintText: 'No limit',
                                        filled: true,
                                        fillColor: AppColors.backgroundColor,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        setModalState(() {
                                          _maxPrice = double.tryParse(value) ?? 100000000;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Quick price buttons
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildPriceChip('Under 1M', 0, 1000000, setModalState),
                                  _buildPriceChip('1M - 5M', 1000000, 5000000, setModalState),
                                  _buildPriceChip('5M - 10M', 5000000, 10000000, setModalState),
                                  _buildPriceChip('10M - 50M', 10000000, 50000000, setModalState),
                                  _buildPriceChip('50M+', 50000000, 100000000, setModalState),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Bedrooms
                        _buildFilterSection(
                          'Bedrooms',
                          Row(
                            children: [
                              Expanded(
                                child: _buildNumberSelector(
                                  'Min',
                                  _minBedrooms,
                                  (value) => setModalState(() => _minBedrooms = value),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildNumberSelector(
                                  'Max',
                                  _maxBedrooms,
                                  (value) => setModalState(() => _maxBedrooms = value),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Bathrooms
                        _buildFilterSection(
                          'Minimum Bathrooms',
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [1, 2, 3, 4, 5, 6].map((bathroomCount) {
                              return _buildSelectableChip(
                                '$bathroomCount+',
                                _minBathrooms == bathroomCount,
                                () {
                                  setModalState(() {
                                    _minBathrooms =
                                        _minBathrooms == bathroomCount ? null : bathroomCount;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Furnishing Status
                        _buildFilterSection(
                          'Furnishing Status',
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _furnishingOptions.map((option) {
                              return _buildSelectableChip(
                                _formatText(option),
                                _selectedFurnishing == option,
                                () {
                                  setModalState(() {
                                    _selectedFurnishing =
                                        _selectedFurnishing == option ? null : option;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Additional Options
                        _buildFilterSection(
                          'Additional Options',
                          Column(
                            children: [
                              _buildSwitchOption(
                                'Negotiable Only',
                                _negotiableOnly ?? false,
                                (value) => setModalState(
                                    () => _negotiableOnly = value ? true : null),
                              ),
                              _buildSwitchOption(
                                'Featured Only',
                                _featuredOnly ?? false,
                                (value) => setModalState(
                                    () => _featuredOnly = value ? true : null),
                              ),
                              _buildSwitchOption(
                                'Verified Only',
                                _verifiedOnly ?? false,
                                (value) => setModalState(
                                    () => _verifiedOnly = value ? true : null),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                
                // Apply Button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _loadProperties();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Show ${_filteredProperties.length} Results',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _buildFilterSection(String title, Widget content) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textColor,
        ),
      ),
      const SizedBox(height: 12),
      content,
    ],
  );
}

Widget _buildSelectableChip(String label, bool isSelected, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textColor,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 14,
        ),
      ),
    ),
  );
}

Widget _buildPriceChip(
  String label,
  double minPrice,
  double maxPrice,
  StateSetter setModalState,
) {
  final bool isSelected = _minPrice == minPrice && _maxPrice == maxPrice;
  
  return GestureDetector(
    onTap: () {
      setModalState(() {
        _minPrice = minPrice;
        _maxPrice = maxPrice;
      });
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textColor,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 13,
        ),
      ),
    ),
  );
}

Widget _buildNumberSelector(
  String label,
  int? value,
  Function(int?) onChanged,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int?>(
            value: value,
            isExpanded: true,
            hint: const Text('Any'),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Any')),
              ...List.generate(10, (i) => i + 1)
                  .map((n) => DropdownMenuItem<int?>(
                        value: n,
                        child: Text('$n'),
                      )),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    ],
  );
}

Widget _buildSwitchOption(String label, bool value, Function(bool) onChanged) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textColor,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primaryColor.withValues(alpha: 0.5),
          activeColor: AppColors.primaryColor,
        ),
      ],
    ),
  );
}
}