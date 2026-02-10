import 'package:flutter/material.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/services/supabase_service.dart';
import 'package:wenest/models/property.dart';
import 'package:wenest/models/property_media.dart';
import 'package:shimmer/shimmer.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:wenest/services/messaging_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class PropertyDetailScreen extends StatefulWidget {
  const PropertyDetailScreen({super.key});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen>
    with SingleTickerProviderStateMixin {
  final _supabaseService = SupabaseService();
  Property? _property;
  List<PropertyMedia> _propertyMedia = [];
  bool _isLoading = true;
  bool _isSaved = false;
  int _currentImageIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  MessagingService? _messagingService;

  // Fallback images
  final List<String> _fallbackImages = [
    'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800&q=80',
    'https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=800&q=80',
    'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=800&q=80',
  ];

  @override
  void initState() {
    super.initState();
    _messagingService = MessagingService(_supabaseService.client);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final propertyId = ModalRoute.of(context)!.settings.arguments;

    String id;
    if (propertyId is String) {
      id = propertyId;
    } else if (propertyId is int) {
      id = propertyId.toString();
    } else {
      debugPrint('Invalid property ID type: ${propertyId.runtimeType}.');
      return;
    }

    _loadProperty(id);
  }

  Future<void> _loadProperty(String propertyId) async {
    setState(() => _isLoading = true);

    try {
      final property = await _supabaseService.getPropertyById(propertyId);
      final media = await _supabaseService.getPropertyMedia(propertyId);

      setState(() {
        _property = property;
        _propertyMedia = media;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading property: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _toggleSave() async {
    if (_property == null) return;

    setState(() => _isSaved = !_isSaved);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                _isSaved
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(_isSaved ? 'Saved to favorites' : 'Removed from favorites'),
            ],
          ),
          backgroundColor:
              _isSaved ? Colors.green.shade700 : Colors.grey.shade700,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _shareProperty() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Share functionality coming soon'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  List<String> get _displayImages {
    if (_propertyMedia.isEmpty) return _fallbackImages;

    final images = _propertyMedia.where((media) => media.isImage).toList()
      ..sort((a, b) {
        if (a.isPrimary && !b.isPrimary) return -1;
        if (!a.isPrimary && b.isPrimary) return 1;
        return a.displayOrder.compareTo(b.displayOrder);
      });

    if (images.isEmpty) return _fallbackImages;
    return images.map((media) => media.fileUrl).toList();
  }

  List<PropertyMedia> get _videoMedia {
    return _propertyMedia.where((m) => m.isVideo).toList();
  }

  bool get _isPropertyOwner {
    final currentUser = _supabaseService.getCurrentUser();
    if (currentUser == null || _property == null) return false;

    return _property!.agentId == currentUser.id ||
        _property!.landlordId == currentUser.id ||
        _property!.agencyId == currentUser.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? _buildShimmerLoading()
          : _property == null
              ? _buildErrorState()
              : _buildPropertyDetails(),
      // Only show contact bar if NOT property owner
      bottomNavigationBar:
          _isLoading || _property == null || _isPropertyOwner
              ? null
              : _buildContactBar(),
      // Only show action buttons if IS property owner
      floatingActionButton: _isLoading || _property == null || !_isPropertyOwner
          ? null
          : _buildOwnerActionButtons(),
    );
  }

  Widget _buildPropertyDetails() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        slivers: [
          // Image Gallery Header
          _buildImageGalleryHeader(),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price & Title Card
                _buildPriceTitleCard(),

                // Property Stats
                if (_hasPropertyStats()) ...[
                  const SizedBox(height: 16),
                  _buildPropertyStatsCard(),
                ],

                const SizedBox(height: 16),

                // Property Details
                _buildPropertyDetailsCard(),

                const SizedBox(height: 16),

                // Description
                _buildDescriptionCard(),

                // Video Section
                if (_videoMedia.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildVideoSection(),
                ],

                // Property Owner Card (only show to non-owners)
                if (!_isPropertyOwner) ...[
                  const SizedBox(height: 16),
                  _buildPropertyOwnerCard(),
                ],

                const SizedBox(height: 16),

                // Location Map
                _buildLocationCard(),

                const SizedBox(height: 16),

                // Engagement Stats (only show to property owners)
                if (_isPropertyOwner) _buildEngagementCard(),

                const SizedBox(height: 16),

                // Amenities/Features
                _buildAmenitiesCard(),

                const SizedBox(height: 140),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGalleryHeader() {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: _buildCircularIconButton(
        icon: Icons.arrow_back_rounded,
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (!_isPropertyOwner)
          _buildCircularIconButton(
            icon: _isSaved
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            onPressed: _toggleSave,
            color: _isSaved ? Colors.red : null,
          ),
        const SizedBox(width: 8),
        _buildCircularIconButton(
          icon: Icons.share_rounded,
          onPressed: _shareProperty,
        ),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image Carousel
            CarouselSlider(
              options: CarouselOptions(
                height: 400,
                viewportFraction: 1.0,
                enableInfiniteScroll: _displayImages.length > 1,
                autoPlay: _displayImages.length > 1,
                autoPlayInterval: const Duration(seconds: 5),
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                onPageChanged: (index, reason) {
                  setState(() => _currentImageIndex = index);
                },
              ),
              items: _displayImages
                  .map((url) => _buildPropertyImage(url))
                  .toList(),
            ),

            // Gradient Overlays
            _buildGradientOverlay(true), // Top
            _buildGradientOverlay(false), // Bottom

            // Image Counter
            if (_displayImages.length > 1)
              Positioned(
                top: 70,
                right: 16,
                child: _buildImageCounter(),
              ),

            // Page Indicators
            if (_displayImages.length > 1)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: _buildPageIndicators(),
              ),

            // Property Badges
            Positioned(
              bottom: 110,
              left: 16,
              right: 16,
              child: _buildPropertyBadges(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientOverlay(bool isTop) {
    return Positioned(
      top: isTop ? 0 : null,
      bottom: isTop ? null : 0,
      left: 0,
      right: 0,
      height: isTop ? 100 : 150,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: isTop ? Alignment.topCenter : Alignment.bottomCenter,
            end: isTop ? Alignment.bottomCenter : Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: isTop ? 0.3 : 0.6),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            '${_currentImageIndex + 1}/${_displayImages.length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _displayImages.asMap().entries.map((entry) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _currentImageIndex == entry.key ? 28 : 8,
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
    );
  }

  Widget _buildPropertyBadges() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (_property!.isFeatured)
          _buildBadge('FEATURED', AppColors.accentColor, Icons.star_rounded),
        if (_property!.negotiable)
          _buildBadge(
              'NEGOTIABLE', AppColors.secondaryColor, Icons.handshake_rounded),
        if (_property!.isVerified)
          _buildBadge('VERIFIED', Colors.green.shade600, Icons.verified_rounded),
      ],
    );
  }

  Widget _buildBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceTitleCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _property!.formattedPrice,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                        height: 1.2,
                      ),
                    ),
                    if (_property!.listingType == 'rent' ||
                        _property!.listingType == 'lease')
                      Text(
                        '/year',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _getListingTypeColor(_property!.listingType)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getListingTypeColor(_property!.listingType),
                    width: 2,
                  ),
                ),
                child: Text(
                  _property!.listingTypeDisplay.toUpperCase(),
                  style: TextStyle(
                    color: _getListingTypeColor(_property!.listingType),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _property!.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 20,
                color: AppColors.primaryColor.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_property!.address}, ${_property!.locationDisplay}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_property!.bedrooms != null && _property!.bedrooms! > 0) ...[
            Expanded(
              child: _buildStatItem(
                Icons.bed_rounded,
                '${_property!.bedrooms}',
                'Bedrooms',
              ),
            ),
          ],
          if (_property!.bedrooms != null &&
              _property!.bedrooms! > 0 &&
              _property!.bathrooms != null &&
              _property!.bathrooms! > 0)
            _buildDivider(),
          if (_property!.bathrooms != null && _property!.bathrooms! > 0) ...[
            Expanded(
              child: _buildStatItem(
                Icons.bathtub_rounded,
                '${_property!.bathrooms}',
                'Bathrooms',
              ),
            ),
          ],
          if ((_property!.bedrooms != null || _property!.bathrooms != null) &&
              _property!.squareMeters != null)
            _buildDivider(),
          if (_property!.squareMeters != null) ...[
            Expanded(
              child: _buildStatItem(
                Icons.square_foot_rounded,
                '${_property!.squareMeters!.toInt()}',
                'sqm',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryColor, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.grey.shade200,
    );
  }

  Widget _buildPropertyDetailsCard() {
    return _buildCard(
      title: 'Property Details',
      child: Column(
        children: [
          _buildDetailRow('Property Type', _property!.propertyTypeDisplay,
              Icons.home_work_rounded),
          _buildRowDivider(),
          _buildDetailRow('Listing Type', _property!.listingTypeDisplay,
              Icons.label_rounded),
          if (_property!.furnishingStatus != null) ...[
            _buildRowDivider(),
            _buildDetailRow('Furnishing', _formatText(_property!.furnishingStatus!),
                Icons.weekend_rounded),
          ],
          if (_property!.yearBuilt != null) ...[
            _buildRowDivider(),
            _buildDetailRow('Year Built', '${_property!.yearBuilt}',
                Icons.calendar_today_rounded),
          ],
          if (_property!.parkingSpaces > 0) ...[
            _buildRowDivider(),
            _buildDetailRow(
              'Parking',
              '${_property!.parkingSpaces} ${_property!.parkingSpaces == 1 ? 'space' : 'spaces'}',
              Icons.local_parking_rounded,
            ),
          ],
          if (_isPropertyOwner) ...[
            _buildRowDivider(),
            _buildDetailRow(
              'Status',
              _property!.status.toUpperCase(),
              Icons.info_rounded,
              statusColor: _getStatusColor(_property!.status),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return _buildCard(
      title: 'Description',
      child: Text(
        _property!.description.isNotEmpty
            ? _property!.description
            : 'No description available for this property.',
        style: TextStyle(
          fontSize: 15,
          color: Colors.grey.shade700,
          height: 1.7,
        ),
      ),
    );
  }

  Widget _buildVideoSection() {
    return _buildCard(
      title: 'Property Video Tour',
      child: GestureDetector(
        onTap: () async {
          final url = Uri.parse(_videoMedia.first.fileUrl);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
        child: Container(
          height: 220,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                color: Colors.grey.shade900,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.videocam_rounded,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Property Video Tour',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyOwnerCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getOwnerInfo(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final ownerInfo = snapshot.data!;
        final name = ownerInfo['name'] as String;
        final type = ownerInfo['type'] as String;
        final verified = ownerInfo['verified'] as bool;
        final phone = ownerInfo['phone'] as String?;
        final ownerId = ownerInfo['id'] as String;

        return _buildCard(
          title: 'Listed By',
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.primaryColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textColor,
                                ),
                              ),
                            ),
                            if (verified)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_rounded,
                                        size: 14, color: Colors.green.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Verified',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          type,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (phone != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _makePhoneCall(phone),
                        icon: const Icon(Icons.phone_rounded, size: 20),
                        label: const Text('Call'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryColor,
                          side:
                              const BorderSide(color: AppColors.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  if (phone != null) const SizedBox(width: 12),
                  Expanded(
                    flex: phone != null ? 2 : 1,
                    child: ElevatedButton.icon(
                      onPressed: () => _startChat(ownerId),
                      icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                      label: const Text('Send Inquiry'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationCard() {
    return _buildCard(
      title: 'Location',
      action: _property!.latitude != null && _property!.longitude != null
          ? TextButton.icon(
              onPressed: () async {
                final url = Uri.parse(
                  'https://www.google.com/maps/search/?api=1&query=${_property!.latitude},${_property!.longitude}',
                );
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.directions_rounded, size: 18),
              label: const Text('Directions'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
              ),
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 220,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(16),
          ),
          child: _property!.latitude != null && _property!.longitude != null
              ? FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(
                        _property!.latitude!, _property!.longitude!),
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.wenest.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                              _property!.latitude!, _property!.longitude!),
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
              : _buildNoLocationWidget(),
        ),
      ),
    );
  }

  Widget _buildEngagementCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withValues(alpha: 0.08),
            AppColors.primaryColor.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Property Engagement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEngagementStat(
                Icons.visibility_rounded,
                '${_property!.viewsCount}',
                'Views',
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.grey.shade300,
              ),
              _buildEngagementStat(
                Icons.favorite_rounded,
                '${_property!.savesCount}',
                'Saves',
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.grey.shade300,
              ),
              _buildEngagementStat(
                Icons.chat_bubble_rounded,
                '${_property!.inquiriesCount}',
                'Inquiries',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.primaryColor, size: 26),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAmenitiesCard() {
    final amenities = <Map<String, dynamic>>[];

    if (_property!.bedrooms != null && _property!.bedrooms! > 0) {
      amenities.add({
        'icon': Icons.bed_rounded,
        'label': '${_property!.bedrooms} Bedrooms'
      });
    }
    if (_property!.bathrooms != null && _property!.bathrooms! > 0) {
      amenities.add({
        'icon': Icons.bathtub_rounded,
        'label': '${_property!.bathrooms} Bathrooms'
      });
    }
    if (_property!.toilets != null && _property!.toilets! > 0) {
      amenities.add({
        'icon': Icons.wc_rounded,
        'label': '${_property!.toilets} Toilets'
      });
    }
    if (_property!.parkingSpaces > 0) {
      amenities.add({
        'icon': Icons.local_parking_rounded,
        'label': '${_property!.parkingSpaces} Parking'
      });
    }
    if (_property!.furnishingStatus != null) {
      amenities.add({
        'icon': Icons.weekend_rounded,
        'label': _formatText(_property!.furnishingStatus!)
      });
    }

    if (amenities.isEmpty) return const SizedBox.shrink();

    return _buildCard(
      title: 'Amenities & Features',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: amenities.map((amenity) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  amenity['icon'] as IconData,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  amenity['label'] as String,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContactBar() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getOwnerInfo(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final ownerInfo = snapshot.data!;
        final phone = ownerInfo['phone'] as String?;
        final ownerId = ownerInfo['id'] as String;

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                if (phone != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _makePhoneCall(phone),
                      icon: const Icon(Icons.phone_rounded, size: 22),
                      label: const Text('Call'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryColor,
                        side: const BorderSide(
                            color: AppColors.primaryColor, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                if (phone != null) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _startChat(ownerId),
                    icon: const Icon(Icons.chat_bubble_rounded, size: 22),
                    label: const Text('Send Inquiry'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      shadowColor:
                          AppColors.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOwnerActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'property_detail_edit_fab',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Edit property coming soon'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: const Icon(Icons.edit_rounded),
        ),
        const SizedBox(height: 16),
        FloatingActionButton.extended(
          heroTag: 'property_detail_share_fab',
          onPressed: _shareProperty,
          icon: const Icon(Icons.share_rounded),
          label: const Text('Share'),
        ),
      ],
    );
  }

  // Helper Widgets

  Widget _buildCard({
    required String title,
    required Widget child,
    Widget? action,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? statusColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (statusColor ?? AppColors.primaryColor)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: statusColor ?? AppColors.primaryColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: statusColor ?? AppColors.textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRowDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Divider(height: 1, color: Colors.grey.shade200),
    );
  }

  Widget _buildCircularIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color ?? AppColors.primaryColor),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildPropertyImage(String imageUrl) {
    return Container(
      width: double.infinity,
      color: Colors.grey.shade200,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey.shade200,
            child: Center(
              child: CircularProgressIndicator(
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.home_rounded,
                size: 80,
                color: AppColors.primaryColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'Image not available',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoLocationWidget() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_rounded,
              size: 50,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Location not available',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 400, color: Colors.white),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 80,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Property Not Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We couldn\'t find the property you\'re looking for. It may have been removed or the link is incorrect.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text(
                'Go Back',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods

  bool _hasPropertyStats() {
    return (_property!.bedrooms != null && _property!.bedrooms! > 0) ||
        (_property!.bathrooms != null && _property!.bathrooms! > 0) ||
        (_property!.squareMeters != null);
  }

  Future<Map<String, dynamic>> _getOwnerInfo() async {
    if (_property!.agentId != null) {
      final agent = await _supabaseService.getAgentById(_property!.agentId!);
      if (agent != null) {
        return {
          'id': agent.profileId,
          'name': agent.displayName ?? agent.fullName ?? 'Agent',
          'type': 'Real Estate Agent',
          'verified': agent.verified,
          'phone': agent.whatsapp ?? agent.phone,
        };
      }
    } else if (_property!.agencyId != null) {
      final agency =
          await _supabaseService.getAgencyById(_property!.agencyId!);
      if (agency != null) {
        return {
          'id': agency.profileId ?? '', // Use profileId 
          'name': agency.name,
          'type': 'Real Estate Agency',
          'verified': agency.verified,
          'phone': agency.phoneNumber,
        };
      }
    } else if (_property!.landlordId != null) {
      final landlord =
          await _supabaseService.getLandlordById(_property!.landlordId!);
      if (landlord != null) {
        return {
          'id': landlord.profileId,
          'name': landlord.companyName ?? 'Property Owner',
          'type': 'Landlord',
          'verified': landlord.verified,
          'phone': landlord.phone,
        };
      }
    }
    return {
      'id': '',
      'name': 'Property Owner',
      'type': 'Owner',
      'verified': false,
      'phone': null,
    };
  }

  Future<void> _startChat(String ownerId) async {
    if (ownerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to start chat - owner information not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Fetch the owner's profile
      final ownerProfile = await _supabaseService.getProfile(ownerId);
      if (ownerProfile == null) {
        if (mounted) Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not load owner profile'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final conversation = await _messagingService!.getOrCreateConversation(
        otherUserId: ownerId,
        propertyId: _property?.id,
      );

      if (mounted) Navigator.pop(context);

      if (mounted) {
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: {
            'conversationId': conversation.id,
            'otherUser': ownerProfile,
          },
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getListingTypeColor(String listingType) {
    switch (listingType.toLowerCase()) {
      case 'sale':
        return Colors.green.shade700;
      case 'rent':
        return Colors.blue.shade700;
      case 'lease':
        return Colors.orange.shade700;
      case 'shortlet':
        return Colors.purple.shade700;
      default:
        return AppColors.primaryColor;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green.shade600;
      case 'pending':
        return Colors.orange.shade600;
      case 'sold':
      case 'rented':
        return Colors.red.shade600;
      default:
        return AppColors.primaryColor;
    }
  }

  String _formatText(String text) {
    return text
        .split('-')
        .map((word) =>
            word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}