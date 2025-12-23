import 'package:flutter/material.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/services/supabase_service.dart';
import 'package:wenest/models/property.dart';
import 'package:shimmer/shimmer.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class PropertyDetailScreen extends StatefulWidget {
  const PropertyDetailScreen({super.key});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final _supabaseService = SupabaseService();
  Property? _property;
  bool _isLoading = true;
  bool _isSaved = false;
  int _currentImageIndex = 0;
  
  // Placeholder images for carousel
  final List<String> _placeholderImages = [
    'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800',
    'https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=800',
    'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=800',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final propertyId = ModalRoute.of(context)!.settings.arguments as int;
    _loadProperty(propertyId);
  }

  Future<void> _loadProperty(int propertyId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final property = await _supabaseService.getPropertyById(propertyId.toString());
      setState(() {
        _property = property;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading property: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openMapsApp() async {
    if (_property?.latitude != null && _property?.longitude != null) {
      final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${_property!.latitude},${_property!.longitude}',
      );
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _openWhatsApp() async {
    final url = Uri.parse('https://wa.me/2348000000000'); // Replace with actual number
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? _buildShimmerLoading()
          : _property == null
              ? _buildErrorState()
              : _buildPropertyDetails(),
      bottomNavigationBar: _isLoading || _property == null
          ? null
          : _buildBottomBar(),
    );
  }

  Widget _buildPropertyDetails() {
    return CustomScrollView(
      slivers: [
        // Image Carousel with Back Button
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.all(8),
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
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.all(8),
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
              child: IconButton(
                icon: Icon(
                  _isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: _isSaved ? Colors.red : AppColors.primaryColor,
                ),
                onPressed: () {
                  setState(() {
                    _isSaved = !_isSaved;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isSaved ? 'Saved to favorites' : 'Removed from favorites'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
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
              child: IconButton(
                icon: const Icon(Icons.share_rounded, color: AppColors.primaryColor),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Share functionality coming soon'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Carousel
                CarouselSlider(
                  options: CarouselOptions(
                    height: 320,
                    viewportFraction: 1.0,
                    enableInfiniteScroll: true,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 4),
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                  ),
                  items: _placeholderImages.map((imageUrl) {
                    return Container(
                      width: double.infinity,
                      color: AppColors.backgroundColor,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.backgroundColor,
                            child: Icon(
                              Icons.home_rounded,
                              size: 100,
                              color: AppColors.primaryColor.withValues(alpha: 0.3),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
                // Image indicator
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _placeholderImages.asMap().entries.map((entry) {
                      return Container(
                        width: _currentImageIndex == entry.key ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentImageIndex == entry.key
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Badges
                Positioned(
                  bottom: 90,
                  left: 16,
                  child: Row(
                    children: [
                      if (_property!.isFeatured)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accentColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'FEATURED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      if (_property!.isFeatured && _property!.negotiable)
                        const SizedBox(width: 8),
                      if (_property!.negotiable)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'NEGOTIABLE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Content
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Price and Title Section
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _property!.formattedPrice,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _getListingTypeColor(_property!.listingType).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _getListingTypeColor(_property!.listingType),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            _property!.listingTypeDisplay,
                            style: TextStyle(
                              color: _getListingTypeColor(_property!.listingType),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _property!.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 20, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${_property!.address}, ${_property!.locationDisplay}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Stats Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    if (_property!.bedrooms != null && _property!.bedrooms! > 0)
                      Expanded(child: _buildStatCard(Icons.bed_rounded, '${_property!.bedrooms}', 'Bedrooms')),
                    if (_property!.bedrooms != null && _property!.bedrooms! > 0 && _property!.bathrooms != null && _property!.bathrooms! > 0)
                      const SizedBox(width: 12),
                    if (_property!.bathrooms != null && _property!.bathrooms! > 0)
                      Expanded(child: _buildStatCard(Icons.bathtub_rounded, '${_property!.bathrooms}', 'Bathrooms')),
                    if ((_property!.bedrooms != null || _property!.bathrooms != null) && _property!.squareMeters != null)
                      const SizedBox(width: 12),
                    if (_property!.squareMeters != null)
                      Expanded(child: _buildStatCard(Icons.square_foot_rounded, '${_property!.squareMeters!.toInt()}', 'sqm')),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Property Details
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Property Type', _property!.propertyTypeDisplay, Icons.home_work_rounded),
                    const Divider(height: 24),
                    _buildDetailRow('Listing Type', _property!.listingTypeDisplay, Icons.label_rounded),
                    if (_property!.furnishingStatus != null) ...[
                      const Divider(height: 24),
                      _buildDetailRow('Furnishing', _formatText(_property!.furnishingStatus!), Icons.weekend_rounded),
                    ],
                    if (_property!.yearBuilt != null) ...[
                      const Divider(height: 24),
                      _buildDetailRow('Year Built', '${_property!.yearBuilt}', Icons.calendar_today_rounded),
                    ],
                    if (_property!.parkingSpaces > 0) ...[
                      const Divider(height: 24),
                      _buildDetailRow('Parking', '${_property!.parkingSpaces} spaces', Icons.local_parking_rounded),
                    ],
                    const Divider(height: 24),
                    _buildDetailRow('Status', _property!.status.toUpperCase(), Icons.info_rounded),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _property!.description ?? 'No description available for this property.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Map Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Location',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColor,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _openMapsApp,
                          icon: const Icon(Icons.directions_rounded, size: 18),
                          label: const Text('Get Directions'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _property!.latitude != null && _property!.longitude != null
                            ? FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(_property!.latitude!, _property!.longitude!),
                                  initialZoom: 15,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.example.wenest',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(_property!.latitude!, _property!.longitude!),
                                        width: 40,
                                        height: 40,
                                        child: const Icon(
                                          Icons.location_on_rounded,
                                          color: Colors.red,
                                          size: 40,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Container(
                                color: AppColors.backgroundColor,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.location_off_rounded, size: 40, color: Colors.grey.shade400),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Location not available',
                                        style: TextStyle(color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Engagement Stats
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildEngagementStat(Icons.visibility_rounded, '${_property!.viewsCount}', 'Views'),
                    Container(width: 1, height: 40, color: Colors.grey.shade300),
                    _buildEngagementStat(Icons.favorite_rounded, '${_property!.savesCount}', 'Saves'),
                    Container(width: 1, height: 40, color: Colors.grey.shade300),
                    _buildEngagementStat(Icons.chat_bubble_rounded, '${_property!.inquiriesCount}', 'Inquiries'),
                  ],
                ),
              ),

              const SizedBox(height: 120), // Space for bottom bar
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEngagementStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryColor, size: 26),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _makePhoneCall('08000000000'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryColor,
                side: const BorderSide(color: AppColors.primaryColor, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.phone_rounded),
              label: const Text('Call', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _openWhatsApp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.chat_bubble_rounded),
              label: const Text('Message', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
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
    return text.split('-').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 320, color: Colors.white),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 32, width: 200, color: Colors.white),
                  const SizedBox(height: 16),
                  Container(height: 20, width: double.infinity, color: Colors.white),
                  const SizedBox(height: 20),
                  Container(height: 100, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text(
            'Property not found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}