import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/services/supabase_service.dart';
import 'package:wenest/models/agent.dart';
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
  
  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityAreaController = TextEditingController();
  final _stateController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _toiletsController = TextEditingController();
  final _squareMetersController = TextEditingController();
  final _yearBuiltController = TextEditingController();
  final _parkingSpacesController = TextEditingController();
  
  String _propertyType = 'apartment';
  String _listingType = 'rent';
  String _furnishingStatus = 'unfurnished';
  bool _negotiable = false;
  bool _isLoading = false;
  int _currentStep = 0;

  // Media files
  final List<XFile> _selectedImages = [];
  XFile? _selectedVideo;
  bool _isUploadingMedia = false;

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
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
      );
      
      setState(() {
        if (_selectedImages.length + images.length <= 10) {
          _selectedImages.addAll(images);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum 10 images allowed'),
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
        setState(() {
          _selectedVideo = video;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking video: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _removeVideo() async {
    setState(() {
      _selectedVideo = null;
    });
  }

  Future<void> _submitProperty({bool publish = false}) async {
    // Validate current step first
    if (_currentStep == 0) {
      if (_titleController.text.trim().isEmpty ||
          _descriptionController.text.trim().isEmpty ||
          _priceController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all required fields in Basic Information'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    if (_currentStep == 1) {
      if (_addressController.text.trim().isEmpty ||
          _cityAreaController.text.trim().isEmpty ||
          _stateController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all required fields in Property Details'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    if (_currentStep == 2) {
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one image'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    // Only proceed with submission on final step
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      return;
    }

    setState(() => _isLoading = true);

    try {
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
        bedrooms: _bedroomsController.text.isEmpty ? null : int.parse(_bedroomsController.text),
        bathrooms: _bathroomsController.text.isEmpty ? null : int.parse(_bathroomsController.text),
        toilets: _toiletsController.text.isEmpty ? null : int.parse(_toiletsController.text),
        squareMeters: _squareMetersController.text.isEmpty ? null : double.parse(_squareMetersController.text),
        yearBuilt: _yearBuiltController.text.isEmpty ? null : int.parse(_yearBuiltController.text),
        furnishingStatus: _furnishingStatus,
        parkingSpaces: _parkingSpacesController.text.isEmpty ? 0 : int.parse(_parkingSpacesController.text),
        negotiable: _negotiable,
      );

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

      if (publish) {
        await _supabaseService.publishProperty(propertyId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(publish ? 'Property published successfully!' : 'Property saved as draft!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploadingMedia = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add New Property'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade900,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: _buildStepContent(),
                ),
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompleted || isActive
                              ? AppColors.primaryColor
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isActive ? Colors.white : Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getStepTitle(index),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          color: isActive
                              ? AppColors.primaryColor
                              : Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (index < 3)
                  Container(
                    width: 20,
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 18),
                    color: index < _currentStep
                        ? AppColors.primaryColor
                        : Colors.grey.shade200,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _getStepTitle(int index) {
    switch (index) {
      case 0:
        return 'Basic';
      case 1:
        return 'Details';
      case 2:
        return 'Media';
      case 3:
        return 'Review';
      default:
        return '';
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildPropertyDetailsStep();
      case 2:
        return _buildMediaStep();
      case 3:
        return _buildReviewStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () {
                    setState(() => _currentStep--);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: AppColors.primaryColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Back'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: _currentStep == 0 ? 1 : 2,
              child: _currentStep < 3
                  ? ElevatedButton(
                      onPressed: _isLoading ? null : () => _submitProperty(publish: false),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Continue'),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _submitProperty(publish: true),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.publish_rounded, size: 20),
                          label: Text(_isLoading ? 'Publishing...' : 'Publish Property'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 46),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _isLoading ? null : () => _submitProperty(publish: false),
                          child: const Text('Save as Draft'),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        
        const Text('Property Title *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'e.g., Modern 3 Bedroom Apartment',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),
        
        const Text('Description *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Describe the property...',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Property Type *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _propertyType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'apartment', child: Text('Apartment')),
                      DropdownMenuItem(value: 'house', child: Text('House')),
                      DropdownMenuItem(value: 'duplex', child: Text('Duplex')),
                      DropdownMenuItem(value: 'bungalow', child: Text('Bungalow')),
                      DropdownMenuItem(value: 'studio', child: Text('Studio')),
                      DropdownMenuItem(value: 'land', child: Text('Land')),
                      DropdownMenuItem(value: 'commercial', child: Text('Commercial')),
                    ],
                    onChanged: (value) => setState(() => _propertyType = value!),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Listing Type *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _listingType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'rent', child: Text('For Rent')),
                      DropdownMenuItem(value: 'sale', child: Text('For Sale')),
                      DropdownMenuItem(value: 'shortlet', child: Text('Shortlet')),
                    ],
                    onChanged: (value) => setState(() => _listingType = value!),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        const Text('Price (₦) *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: 'Enter amount',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
        const SizedBox(height: 10),
        
        CheckboxListTile(
          value: _negotiable,
          onChanged: (value) => setState(() => _negotiable = value!),
          title: const Text('Price is negotiable', style: TextStyle(fontSize: 14)),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildPropertyDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Property Details',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        
        const Text('Address *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            hintText: 'e.g., 123 Main Street',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('City/Area *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _cityAreaController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Ikeja',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('State *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _stateController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Lagos',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        const Text(
          'Room Configuration',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildNumberField('Bedrooms', _bedroomsController, Icons.bed_rounded),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildNumberField('Bathrooms', _bathroomsController, Icons.bathtub_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildNumberField('Toilets', _toiletsController, Icons.wc_rounded),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildNumberField('Parking', _parkingSpacesController, Icons.local_parking_rounded),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        Row(
          children: [
            Expanded(
              child: _buildNumberField('Size (m²)', _squareMetersController, Icons.square_foot_rounded, isDecimal: true),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildNumberField('Year Built', _yearBuiltController, Icons.calendar_today_rounded),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        const Text('Furnishing Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _furnishingStatus,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          items: const [
            DropdownMenuItem(value: 'unfurnished', child: Text('Unfurnished')),
            DropdownMenuItem(value: 'semi-furnished', child: Text('Semi-Furnished')),
            DropdownMenuItem(value: 'fully-furnished', child: Text('Fully Furnished')),
          ],
          onChanged: (value) => setState(() => _furnishingStatus = value!),
        ),
      ],
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller, IconData icon, {bool isDecimal = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
          inputFormatters: [
            if (!isDecimal) FilteringTextInputFormatter.digitsOnly,
            if (isDecimal) FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Property Media',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Property Images *', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text(
              '${_selectedImages.length}/10',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _selectedImages.length + 1,
          itemBuilder: (context, index) {
            if (index == _selectedImages.length) {
              return InkWell(
                onTap: _selectedImages.length < 10 ? _pickImages : null,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedImages.length < 10 ? AppColors.primaryColor : Colors.grey.shade300,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    color: _selectedImages.length < 10 
                        ? AppColors.primaryColor.withValues(alpha: 0.05) 
                        : Colors.grey.shade100,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_rounded,
                        size: 32,
                        color: _selectedImages.length < 10 ? AppColors.primaryColor : Colors.grey,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 11,
                          color: _selectedImages.length < 10 ? AppColors.primaryColor : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
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
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                    ),
                  ),
                ),
                if (index == 0)
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Cover',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      
        const SizedBox(height: 20),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Property Video (Optional)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            if (_selectedVideo != null)
              TextButton(
                onPressed: _removeVideo,
                child: const Text('Remove', style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (_selectedVideo == null)
          InkWell(
            onTap: _pickVideo,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam_rounded, size: 36, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text('Add Video', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ),
          )
        else
          Container(
            height: 90,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primaryColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.play_circle_filled_rounded, size: 36, color: AppColors.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Video Added',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedVideo!.name,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Your Property',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        
        if (_isUploadingMedia)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Expanded(
                  child: Text('Uploading media files...\nThis may take a few moments.'),
                ),
              ],
            ),
          ),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReviewItem('Title', _titleController.text),
              _buildReviewItem('Description', _descriptionController.text),
              _buildReviewItem('Property Type', _propertyType.toUpperCase()),
              _buildReviewItem('Listing Type', _listingType.toUpperCase()),
              _buildReviewItem('Price', '₦${_priceController.text}${_negotiable ? ' (Negotiable)' : ''}'),
              
              if (_bedroomsController.text.isNotEmpty || _bathroomsController.text.isNotEmpty)
                _buildReviewItem(
                  'Rooms',
                  '${_bedroomsController.text.isEmpty ? '0' : _bedroomsController.text} Bed • '
                  '${_bathroomsController.text.isEmpty ? '0' : _bathroomsController.text} Bath'
                ),
              
              if (_squareMetersController.text.isNotEmpty)
                _buildReviewItem('Size', '${_squareMetersController.text} m²'),
              
              _buildReviewItem('Furnishing', _furnishingStatus.toUpperCase()),
              _buildReviewItem('Address', _addressController.text),
              _buildReviewItem('Location', '${_cityAreaController.text}, ${_stateController.text}'),
              
              const Divider(height: 20),
              
              _buildReviewItem('Images', '${_selectedImages.length} image(s)'),
              if (_selectedVideo != null)
                _buildReviewItem('Video', '1 video added'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 13),
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