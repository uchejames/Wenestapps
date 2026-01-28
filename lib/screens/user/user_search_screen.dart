import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/services/supabase_service.dart';
import 'package:wenest/models/property.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

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
  String? _selectedFurnishing;
  double _minPrice = 0;
  double _maxPrice = 100000000;
  int? _minBedrooms;
  int? _maxBedrooms;
  int? _minBathrooms;
  bool? _negotiableOnly;
  bool? _featuredOnly;
  bool? _verifiedOnly;

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

  final List<String> _states = [
    'Lagos',
    'Abuja',
    'Rivers',
    'Oyo',
    'Kano',
    'Delta',
    'Enugu',
    'Anambra',
  ];

  final List<String> _furnishingOptions = [
    'unfurnished',
    'semi-furnished',
    'fully-furnished',
  ];

  @override
  void initState() {
    super.initState();
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
            backgroundColor: Colors.red,
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

  int _getActiveFiltersCount() {
    int count = 0;
    if (_selectedPropertyType != null) count++;
    if (_selectedListingType != null) count++;
    if (_selectedState != null) count++;
    if (_selectedFurnishing != null) count++;
    if (_minPrice > 0 || _maxPrice < 100000000) count++;
    if (_minBedrooms != null || _maxBedrooms != null) count++;
    if (_minBathrooms != null) count++;
    if (_negotiableOnly == true) count++;
    if (_featuredOnly == true) count++;
    if (_verifiedOnly == true) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8), // replaced withValues(alpha: 0.03)
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
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search location, property...',
                          hintStyle:
                              TextStyle(color: Colors.grey.shade500, fontSize: 15),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: Colors.grey.shade400, size: 22),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _showFilterBottomSheet(),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withAlpha(77), // 0.3 * 255 ≈ 77
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          const Icon(Icons.tune_rounded,
                              color: Colors.white, size: 22),
                          if (_getActiveFiltersCount() > 0)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.accentColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${_getActiveFiltersCount()}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Active Filter Chips
            if (_getActiveFiltersCount() > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (_selectedPropertyType != null)
                        _buildFilterChip(_formatText(_selectedPropertyType!), () {
                          setState(() => _selectedPropertyType = null);
                          _loadProperties();
                        }),
                      if (_selectedListingType != null)
                        _buildFilterChip(
                            'For ${_formatText(_selectedListingType!)}', () {
                          setState(() => _selectedListingType = null);
                          _loadProperties();
                        }),
                      if (_selectedState != null)
                        _buildFilterChip(_selectedState!, () {
                          setState(() => _selectedState = null);
                          _loadProperties();
                        }),
                      if (_minBedrooms != null || _maxBedrooms != null)
                        _buildFilterChip(
                            '${_minBedrooms ?? 0}-${_maxBedrooms ?? "Any"} Beds',
                            () {
                          setState(() {
                            _minBedrooms = null;
                            _maxBedrooms = null;
                          });
                          _loadProperties();
                        }),
                      if (_minBathrooms != null)
                        _buildFilterChip('$_minBathrooms+ Baths', () {
                          setState(() => _minBathrooms = null);
                          _applyFilters();
                        }),
                      if (_negotiableOnly == true)
                        _buildFilterChip('Negotiable', () {
                          setState(() => _negotiableOnly = null);
                          _applyFilters();
                        }),
                      if (_verifiedOnly == true)
                        _buildFilterChip('Verified', () {
                          setState(() => _verifiedOnly = null);
                          _applyFilters();
                        }),
                      // Clear All
                      GestureDetector(
                        onTap: _clearFilters,
                        child: Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.close_rounded,
                                  size: 14, color: Colors.red.shade700),
                              const SizedBox(width: 4),
                              Text(
                                'Clear All',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
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

            // Results Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_filteredProperties.length} properties found',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Properties Grid
            Expanded(
              child: _isLoading
                  ? _buildShimmerGrid()
                  : _filteredProperties.isEmpty
                      ? _buildEmptyState()
                      : GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _filteredProperties.length,
                          itemBuilder: (context, index) {
                            return _buildPropertyCard(
                                _filteredProperties[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withAlpha(26), // ~0.1 opacity
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.primaryColor.withAlpha(77)), // ~0.3
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(Property property) {
    return GestureDetector(
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
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section - UPDATED TO USE REAL IMAGES
            Stack(
              children: [
                Container(
                  height: 120,
                  decoration: const BoxDecoration(
                    color: AppColors.backgroundColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: property.primaryImageUrl != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(
                            property.primaryImageUrl!,
                            width: double.infinity,
                            height: 120,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  color: AppColors.primaryColor,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.home_rounded,
                                  size: 40,
                                  color: AppColors.primaryColor.withAlpha(51),
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.home_rounded,
                            size: 40,
                            color: AppColors.primaryColor.withAlpha(51),
                          ),
                        ),
                ),
                // Listing Type Badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getListingTypeColor(property.listingType),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      property.listingTypeDisplay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Featured Badge
                if (property.isFeatured)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'FEATURED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Details Section (rest stays the same)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.formattedPrice,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      property.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 2),
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
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        property.propertyTypeDisplay,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (property.bedrooms != null && property.bedrooms! > 0) ...[
                          Icon(Icons.bed_rounded, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 2),
                          Text('${property.bedrooms}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                          const SizedBox(width: 8),
                        ],
                        if (property.bathrooms != null && property.bathrooms! > 0) ...[
                          Icon(Icons.bathtub_rounded, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 2),
                          Text('${property.bathrooms}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
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

  String _formatText(String text) {
    return text[0].toUpperCase() + text.substring(1).replaceAll('-', ' ');
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No properties found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
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
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  decoration: BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedPropertyType = null;
                            _selectedListingType = null;
                            _selectedState = null;
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
                        child: const Text(
                          'Reset All',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        _buildFilterSection(
                          'Listing Type',
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _listingTypes.map((type) {
                              return _buildSelectableChip(
                                'For ${_formatText(type)}',
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
                        _buildFilterSection(
                          'Location',
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _states.map((state) {
                              return _buildSelectableChip(
                                state,
                                _selectedState == state,
                                () {
                                  setModalState(() {
                                    _selectedState =
                                        _selectedState == state ? null : state;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildFilterSection(
                          'Price Range',
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '₦${_minPrice.toInt()}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '₦${_maxPrice >= 100000000 ? "100M+" : _maxPrice.toInt()}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              RangeSlider(
                                values: RangeValues(_minPrice, _maxPrice),
                                min: 0,
                                max: 100000000,
                                divisions: 100,
                                activeColor: AppColors.primaryColor,
                                inactiveColor: Colors.grey.shade300,
                                onChanged: (values) {
                                  setModalState(() {
                                    _minPrice = values.start;
                                    _maxPrice = values.end;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildFilterSection(
                          'Bedrooms',
                          Row(
                            children: [
                              Expanded(
                                child: _buildNumberSelector(
                                  'Min',
                                  _minBedrooms,
                                  (value) =>
                                      setModalState(() => _minBedrooms = value),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildNumberSelector(
                                  'Max',
                                  _maxBedrooms,
                                  (value) =>
                                      setModalState(() => _maxBedrooms = value),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
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
                        color: Colors.black.withAlpha(13), // ~0.05
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
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
      ),
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

  Widget _buildSelectableChip(
      String label, bool isSelected, VoidCallback onTap) {
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

  Widget _buildNumberSelector(
      String label, int? value, Function(int?) onChanged) {
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
            color: Colors.grey.shade50,
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
            activeTrackColor: AppColors.primaryColor.withAlpha(128),
            activeThumbColor: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }
}