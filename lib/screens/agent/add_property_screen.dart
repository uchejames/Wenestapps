import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/services/supabase_service.dart';
import 'package:wenest/models/agent.dart';
import 'package:wenest/models/amenity.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddPropertyScreen extends StatefulWidget {
  final Agent agent;

  const AddPropertyScreen({super.key, required this.agent});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();
  final _imagePicker = ImagePicker();
  final PageController _pageController = PageController();
  
  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityAreaController = TextEditingController();
  final _stateController = TextEditingController();
  final _bedroomsController = TextEditingController(text: '0');
  final _bathroomsController = TextEditingController(text: '0');
  final _toiletsController = TextEditingController(text: '0');
  final _squareMetersController = TextEditingController();
  final _yearBuiltController = TextEditingController();
  final _parkingSpacesController = TextEditingController(text: '0');
  
  String _propertyType = 'apartment';
  String _listingType = 'rent';
  String _furnishingStatus = 'unfurnished';
  bool _negotiable = false;
  bool _isLoading = false;
  bool _isUploadingMedia = false;
  bool _isLoadingAmenities = true;
  int _currentPage = 0;

  // Media files
  final List<XFile> _selectedImages = [];
  XFile? _selectedVideo;

  // Amenities
  List<Amenity> _availableAmenities = [];
  final Set<int> _selectedAmenityIds = {}; // Changed from String to int

  @override
  void initState() {
    super.initState();
    _loadAmenities();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _cityAreaController.dispose();
    _stateController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _toiletsController.dispose();
    _squareMetersController.dispose();
    _yearBuiltController.dispose();
    _parkingSpacesController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadAmenities() async {
    try {
      print('DEBUG: Starting to load amenities...');
      setState(() => _isLoadingAmenities = true);
      
      final amenities = await _supabaseService.getAllAmenities();
      
      print('DEBUG: Received ${amenities.length} amenities');
      if (amenities.isNotEmpty) {
        print('DEBUG: First amenity - ID: ${amenities.first.id}, Name: ${amenities.first.name}, Category: ${amenities.first.category}');
      }
      
      setState(() {
        _availableAmenities = amenities;
        _isLoadingAmenities = false;
      });
      
      print('DEBUG: Amenities loaded successfully. Count: ${_availableAmenities.length}');
    } catch (e, stackTrace) {
      print('DEBUG ERROR: Failed to load amenities: $e');
      print('DEBUG STACKTRACE: $stackTrace');
      
      setState(() => _isLoadingAmenities = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading amenities: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
      );
      
      setState(() {
        final remainingSlots = 10 - _selectedImages.length;
        if (images.length <= remainingSlots) {
          _selectedImages.addAll(images);
        } else {
          _selectedImages.addAll(images.take(remainingSlots));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maximum 10 images allowed. Added ${remainingSlots} images.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );
      
      if (video != null) {
        final fileSize = await File(video.path).length();
        if (fileSize > 100 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video size must be less than 100MB'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        setState(() => _selectedVideo = video);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking video: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  void _removeVideo() {
    setState(() => _selectedVideo = null);
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0: // Basic Information
        if (_titleController.text.trim().isEmpty) {
          _showError('Please enter a property title');
          return false;
        }
        if (_descriptionController.text.trim().isEmpty) {
          _showError('Please enter a property description');
          return false;
        }
        if (_priceController.text.trim().isEmpty) {
          _showError('Please enter a price');
          return false;
        }
        final price = double.tryParse(_priceController.text.trim());
        if (price == null || price <= 0) {
          _showError('Please enter a valid price');
          return false;
        }
        return true;

      case 1: // Property Details
        if (_addressController.text.trim().isEmpty) {
          _showError('Please enter the property address');
          return false;
        }
        if (_cityAreaController.text.trim().isEmpty) {
          _showError('Please enter the city/area');
          return false;
        }
        if (_stateController.text.trim().isEmpty) {
          _showError('Please enter the state');
          return false;
        }
        return true;

      case 2: // Photos & Video
        if (_selectedImages.isEmpty) {
          _showError('Please add at least one property image');
          return false;
        }
        return true;

      case 3: // Amenities - optional, always valid
        return true;

      default:
        return true;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _nextPage() {
    if (_validateCurrentPage()) {
      if (_currentPage < 4) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitProperty() async {
    if (!_validateCurrentPage()) return;

    setState(() => _isLoading = true);

    try {
      // Create property
      final propertyId = await _supabaseService.createProperty(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        propertyType: _propertyType,
        listingType: _listingType,
        price: double.parse(_priceController.text.trim()),
        address: _addressController.text.trim(),
        cityArea: _cityAreaController.text.trim(),
        state: _stateController.text.trim(),
        agentId: widget.agent.id,
        agencyId: widget.agent.agencyId,
        bedrooms: int.tryParse(_bedroomsController.text) ?? 0,
        bathrooms: int.tryParse(_bathroomsController.text) ?? 0,
        toilets: int.tryParse(_toiletsController.text) ?? 0,
        squareMeters: double.tryParse(_squareMetersController.text),
        yearBuilt: int.tryParse(_yearBuiltController.text),
        furnishingStatus: _furnishingStatus,
        parkingSpaces: int.tryParse(_parkingSpacesController.text) ?? 0,
        negotiable: _negotiable,
      );

      // Upload media
      setState(() => _isUploadingMedia = true);
      
      for (int i = 0; i < _selectedImages.length; i++) {
        await _supabaseService.uploadPropertyMedia(
          propertyId: propertyId,
          file: File(_selectedImages[i].path),
          mediaType: 'image',
          displayOrder: i,
        );
      }

      if (_selectedVideo != null) {
        await _supabaseService.uploadPropertyMedia(
          propertyId: propertyId,
          file: File(_selectedVideo!.path),
          mediaType: 'video',
          displayOrder: _selectedImages.length,
        );
      }

      // Add amenities
      if (_selectedAmenityIds.isNotEmpty) {
        for (int amenityId in _selectedAmenityIds) {
          await _supabaseService.addPropertyAmenity(
            propertyId: propertyId,
            amenityId: amenityId.toString(), // Convert to String for service method
          );
        }
      }

      setState(() {
        _isLoading = false;
        _isUploadingMedia = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Property created successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        // Navigate back after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isUploadingMedia = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating property: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add New Property',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _buildBasicInformationPage(),
                _buildPropertyDetailsPage(),
                _buildPhotosVideoPage(),
                _buildAmenitiesPage(),
                _buildReviewPage(),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            children: List.generate(5, (index) {
              final isCompleted = index < _currentPage;
              final isCurrent = index == _currentPage;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: isCompleted || isCurrent
                        ? AppColors.primaryColor
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            _getPageTitle(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (_currentPage) {
      case 0:
        return 'Step 1: Basic Information';
      case 1:
        return 'Step 2: Property Details';
      case 2:
        return 'Step 3: Photos & Video';
      case 3:
        return 'Step 4: Amenities';
      case 4:
        return 'Step 5: Review & Submit';
      default:
        return '';
    }
  }

  Widget _buildNavigationButtons() {
    return Container(
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
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _previousPage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentPage > 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : _currentPage < 4
                      ? _nextPage
                      : _submitProperty,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading || _isUploadingMedia
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _currentPage < 4 ? 'Continue' : 'Submit Property',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // PAGE 1: BASIC INFORMATION
  Widget _buildBasicInformationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Information',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by providing the essential details about your property',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // Property Title
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Property Title *',
              hintText: 'e.g., Luxury 3-Bedroom Apartment in Ikoyi',
              prefixIcon: const Icon(Icons.title_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            textCapitalization: TextCapitalization.words,
            maxLength: 100,
          ),
          const SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description *',
              hintText: 'Describe the property features, location, and highlights',
              prefixIcon: const Icon(Icons.description_outlined),
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            maxLines: 5,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 24),

          // Property Type & Listing Type
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Property Type *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _propertyType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'apartment', child: Text('Apartment')),
                        DropdownMenuItem(value: 'house', child: Text('House')),
                        DropdownMenuItem(value: 'condo', child: Text('Condo')),
                        DropdownMenuItem(value: 'land', child: Text('Land')),
                        DropdownMenuItem(value: 'commercial', child: Text('Commercial')),
                        DropdownMenuItem(value: 'office', child: Text('Office')),
                        DropdownMenuItem(value: 'warehouse', child: Text('Warehouse')),
                      ],
                      onChanged: (value) => setState(() => _propertyType = value!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Listing Type *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _listingType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'rent', child: Text('For Rent')),
                        DropdownMenuItem(value: 'sale', child: Text('For Sale')),
                        DropdownMenuItem(value: 'lease', child: Text('For Lease')),
                        DropdownMenuItem(value: 'shortlet', child: Text('Shortlet')),
                      ],
                      onChanged: (value) => setState(() => _listingType = value!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Price
          Text(
            'Price *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _priceController,
            decoration: InputDecoration(
              labelText: 'Price (NGN)',
              hintText: '0',
              prefixIcon: const Icon(Icons.currency_exchange_rounded),
              prefixText: '₦ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),
          
          CheckboxListTile(
            value: _negotiable,
            onChanged: (value) => setState(() => _negotiable = value ?? false),
            title: const Text('Price is negotiable'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
          ),
        ],
      ),
    );
  }

  // PAGE 2: PROPERTY DETAILS
  Widget _buildPropertyDetailsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Property Details',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add specific details about the property',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // Location Section
          Text(
            'Location *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Street Address',
              hintText: 'e.g., 123 Main Street',
              prefixIcon: const Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cityAreaController,
                  decoration: InputDecoration(
                    labelText: 'City/Area',
                    hintText: 'e.g., Ikoyi',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _stateController,
                  decoration: InputDecoration(
                    labelText: 'State',
                    hintText: 'e.g., Lagos',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Property Features
          Text(
            'Property Features',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  controller: _bedroomsController,
                  label: 'Bedrooms',
                  icon: Icons.bed_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumberField(
                  controller: _bathroomsController,
                  label: 'Bathrooms',
                  icon: Icons.bathtub_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  controller: _toiletsController,
                  label: 'Toilets',
                  icon: Icons.wc_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumberField(
                  controller: _parkingSpacesController,
                  label: 'Parking',
                  icon: Icons.local_parking_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Additional Details
          Text(
            'Additional Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _squareMetersController,
            decoration: InputDecoration(
              labelText: 'Size (Square Meters)',
              hintText: 'e.g., 120',
              prefixIcon: const Icon(Icons.square_foot_outlined),
              suffixText: 'm²',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _yearBuiltController,
            decoration: InputDecoration(
              labelText: 'Year Built',
              hintText: 'e.g., 2020',
              prefixIcon: const Icon(Icons.calendar_today_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Furnishing Status',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _furnishingStatus,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              prefixIcon: const Icon(Icons.weekend_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'unfurnished', child: Text('Unfurnished')),
              DropdownMenuItem(value: 'semi-furnished', child: Text('Semi-Furnished')),
              DropdownMenuItem(value: 'fully-furnished', child: Text('Fully Furnished')),
            ],
            onChanged: (value) => setState(() => _furnishingStatus = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }

  // PAGE 3: PHOTOS & VIDEO
  Widget _buildPhotosVideoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Photos & Video',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add high-quality photos and optional video tour',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // Property Images
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Property Images *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_selectedImages.length}/10',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Add Images Button
          InkWell(
            onTap: _selectedImages.length < 10 ? _pickImages : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primaryColor,
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(16),
                color: AppColors.primaryColor.withValues(alpha: 0.05),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 48,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedImages.isEmpty
                          ? 'Add Photos'
                          : 'Add More Photos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Maximum 10 images',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_selectedImages[index].path),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    if (index == 0)
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'COVER',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],

          const SizedBox(height: 32),

          // Property Video
          const Text(
            'Property Video (Optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (_selectedVideo == null)
            InkWell(
              onTap: _pickVideo,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade50,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.videocam_outlined,
                        size: 40,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add Video Tour',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'Max 2 minutes, 100MB',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.play_circle_filled_rounded,
                      size: 36,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Video Added',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedVideo!.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _removeVideo,
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // PAGE 4: AMENITIES
  Widget _buildAmenitiesPage() {
    if (_isLoadingAmenities) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Group amenities by category
    final Map<String, List<Amenity>> groupedAmenities = {};
    for (var amenity in _availableAmenities) {
      final category = amenity.category ?? 'Other';
      if (!groupedAmenities.containsKey(category)) {
        groupedAmenities[category] = [];
      }
      groupedAmenities[category]!.add(amenity);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Amenities',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the amenities available at this property',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // Display amenities by category
          ...groupedAmenities.entries.map((entry) {
            final category = entry.key;
            final amenities = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: amenities.map((amenity) {
                    final isSelected = _selectedAmenityIds.contains(amenity.id);
                    return FilterChip(
                      label: Text(amenity.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedAmenityIds.add(amenity.id);
                          } else {
                            _selectedAmenityIds.remove(amenity.id);
                          }
                        });
                      },
                      selectedColor: AppColors.primaryColor.withValues(alpha: 0.2),
                      checkmarkColor: AppColors.primaryColor,
                      backgroundColor: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primaryColor
                              : Colors.grey.shade300,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
            );
          }).toList(),

          if (_selectedAmenityIds.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_selectedAmenityIds.length} amenities selected',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // PAGE 5: REVIEW
  Widget _buildReviewPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review & Submit',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review all details before submitting your property',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          if (_isUploadingMedia)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Uploading media files...',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'This may take a few moments',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          _buildReviewSection('Basic Information', [
            _buildReviewItem('Title', _titleController.text),
            _buildReviewItem('Description', _descriptionController.text),
            _buildReviewItem('Property Type', _propertyType.toUpperCase()),
            _buildReviewItem('Listing Type', _listingType.toUpperCase()),
            _buildReviewItem(
              'Price',
              '₦${_priceController.text}${_negotiable ? ' (Negotiable)' : ''}',
            ),
          ]),
          const SizedBox(height: 16),

          _buildReviewSection('Property Details', [
            _buildReviewItem('Address', _addressController.text),
            _buildReviewItem(
              'Location',
              '${_cityAreaController.text}, ${_stateController.text}',
            ),
            _buildReviewItem(
              'Rooms',
              '${_bedroomsController.text} Bed • ${_bathroomsController.text} Bath • ${_toiletsController.text} Toilet',
            ),
            if (_squareMetersController.text.isNotEmpty)
              _buildReviewItem('Size', '${_squareMetersController.text} m²'),
            if (_yearBuiltController.text.isNotEmpty)
              _buildReviewItem('Year Built', _yearBuiltController.text),
            _buildReviewItem('Furnishing', _furnishingStatus.toUpperCase()),
            _buildReviewItem('Parking Spaces', _parkingSpacesController.text),
          ]),
          const SizedBox(height: 16),

          _buildReviewSection('Media', [
            _buildReviewItem('Photos', '${_selectedImages.length} image(s)'),
            if (_selectedVideo != null)
              _buildReviewItem('Video', '1 video added'),
          ]),
          const SizedBox(height: 16),

          if (_selectedAmenityIds.isNotEmpty)
            _buildReviewSection('Amenities', [
              _buildReviewItem(
                'Selected',
                '${_selectedAmenityIds.length} amenities',
              ),
            ]),
        ],
      ),
    );
  }

  Widget _buildReviewSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}