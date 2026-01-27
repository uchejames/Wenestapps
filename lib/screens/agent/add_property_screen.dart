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
  List<XFile> _selectedImages = [];
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2), // 2 minute limit
      );
      
      if (video != null) {
        final fileSize = await File(video.path).length();
        if (fileSize > 100 * 1024 * 1024) { // 100MB limit
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking video: $e'), backgroundColor: Colors.red),
      );
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
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create property first
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

      // Upload images
      setState(() => _isUploadingMedia = true);
      for (int i = 0; i < _selectedImages.length; i++) {
        await _supabaseService.uploadPropertyMedia(
          propertyId: propertyId,
          file: File(_selectedImages[i].path),
          mediaType: 'image',
          displayOrder: i,
        );
      }

      // Upload video if selected
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
      appBar: AppBar(
        title: const Text('Add New Property'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 3) {
              // Validate current step before moving
              if (_validateCurrentStep()) {
                setState(() => _currentStep++);
              }
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  if (_currentStep < 3)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Continue'),
                      ),
                    ),
                  if (_currentStep == 3) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => _submitProperty(publish: false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isLoading && !_isUploadingMedia
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Save as Draft'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _submitProperty(publish: true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Publish'),
                      ),
                    ),
                  ],
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _isLoading ? null : details.onStepCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      child: const Text('Back'),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Basic Information'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: _buildBasicInfoStep(),
            ),
            Step(
              title: const Text('Property Details'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: _buildPropertyDetailsStep(),
            ),
            Step(
              title: const Text('Location & Media'),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
              content: _buildLocationAndMediaStep(),
            ),
            Step(
              title: const Text('Review & Publish'),
              isActive: _currentStep >= 3,
              state: StepState.indexed,
              content: _buildReviewStep(),
            ),
          ],
        ),
      ),
    );
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_titleController.text.trim().isEmpty) {
          _showError('Please enter property title');
          return false;
        }
        if (_descriptionController.text.trim().isEmpty) {
          _showError('Please enter property description');
          return false;
        }
        if (_priceController.text.trim().isEmpty) {
          _showError('Please enter property price');
          return false;
        }
        return true;
      case 1:
        // Property details validation
        return true;
      case 2:
        if (_addressController.text.trim().isEmpty) {
          _showError('Please enter property address');
          return false;
        }
        if (_cityAreaController.text.trim().isEmpty) {
          _showError('Please enter city/area');
          return false;
        }
        if (_stateController.text.trim().isEmpty) {
          _showError('Please enter state');
          return false;
        }
        if (_selectedImages.isEmpty) {
          _showError('Please add at least one image');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
    );
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Property Title', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'e.g., Modern 3 Bedroom Apartment',
            prefixIcon: Icon(Icons.title_rounded),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Title is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        
        const Text('Description', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Describe the property in detail...',
            alignLabelWithHint: true,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Description is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Property Type', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _propertyType,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.home_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'apartment', child: Text('Apartment')),
                      DropdownMenuItem(value: 'house', child: Text('House')),
                      DropdownMenuItem(value: 'duplex', child: Text('Duplex')),
                      DropdownMenuItem(value: 'villa', child: Text('Villa')),
                      DropdownMenuItem(value: 'land', child: Text('Land')),
                      DropdownMenuItem(value: 'commercial', child: Text('Commercial')),
                      DropdownMenuItem(value: 'office', child: Text('Office Space')),
                      DropdownMenuItem(value: 'shop', child: Text('Shop')),
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
                  const Text('Listing Type', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _listingType,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.sell_rounded),
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
        const SizedBox(height: 20),
        
        const Text('Price (₦)', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: 'Enter amount',
            prefixIcon: const Icon(Icons.attach_money_rounded),
            suffix: Text(
              _listingType == 'rent' ? '/year' : _listingType == 'shortlet' ? '/night' : '',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Price is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        CheckboxListTile(
          title: const Text('Price is negotiable'),
          value: _negotiable,
          onChanged: (value) => setState(() => _negotiable = value ?? false),
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
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bedrooms', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _bedroomsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: '0',
                      prefixIcon: Icon(Icons.bed_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bathrooms', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _bathroomsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: '0',
                      prefixIcon: Icon(Icons.bathtub_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Toilets', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _toiletsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: '0',
                      prefixIcon: Icon(Icons.wc_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Square Meters', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _squareMetersController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: '0',
                      prefixIcon: Icon(Icons.square_foot_rounded),
                      suffixText: 'm²',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Parking Spaces', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _parkingSpacesController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: '0',
                      prefixIcon: Icon(Icons.local_parking_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Year Built', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _yearBuiltController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: 'YYYY',
                      prefixIcon: Icon(Icons.calendar_today_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Furnishing', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _furnishingStatus,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.chair_rounded),
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
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationAndMediaStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Address', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            hintText: 'Enter full address',
            prefixIcon: Icon(Icons.location_on_rounded),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Address is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('City/Area', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _cityAreaController,
                    decoration: const InputDecoration(
                      hintText: 'e.g., Lekki',
                      prefixIcon: Icon(Icons.location_city_rounded),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'City/Area is required';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('State', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      hintText: 'e.g., Lagos',
                      prefixIcon: Icon(Icons.map_rounded),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'State is required';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        const Divider(),
        const SizedBox(height: 16),
        
        // Images Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Property Images', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${_selectedImages.length}/10', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),
        
        if (_selectedImages.isEmpty)
          Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 2, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: _pickImages,
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_rounded, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text('Add Images', style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text('(Maximum 10 images)', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _selectedImages.length) {
                      if (_selectedImages.length < 10) {
                        return InkWell(
                          onTap: _pickImages,
                          child: Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_rounded, color: Colors.grey.shade400),
                                Text('Add More', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    }
                    
                    return Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(File(_selectedImages[index].path)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: InkWell(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
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
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        
        const SizedBox(height: 24),
        
        // Video Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Property Video (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (_selectedVideo != null)
              TextButton.icon(
                onPressed: _removeVideo,
                icon: const Icon(Icons.delete_rounded, size: 18),
                label: const Text('Remove'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Max 2 minutes, 100MB',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        
        if (_selectedVideo == null)
          InkWell(
            onTap: _pickVideo,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 2, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam_rounded, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text('Add Video', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ),
          )
        else
          Container(
            height: 100,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.play_circle_filled_rounded, size: 40, color: AppColors.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Video Added',
                        style: TextStyle(fontWeight: FontWeight.w600),
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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        if (_isUploadingMedia)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
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
        
        _buildReviewItem('Title', _titleController.text),
        _buildReviewItem('Description', _descriptionController.text),
        _buildReviewItem('Property Type', _propertyType.toUpperCase()),
        _buildReviewItem('Listing Type', _listingType.toUpperCase()),
        _buildReviewItem('Price', '₦${_priceController.text}${_negotiable ? ' (Negotiable)' : ''}'),
        
        if (_bedroomsController.text.isNotEmpty || _bathroomsController.text.isNotEmpty || _toiletsController.text.isNotEmpty)
          _buildReviewItem(
            'Rooms',
            '${_bedroomsController.text.isEmpty ? '0' : _bedroomsController.text} Bed • '
            '${_bathroomsController.text.isEmpty ? '0' : _bathroomsController.text} Bath • '
            '${_toiletsController.text.isEmpty ? '0' : _toiletsController.text} Toilet'
          ),
        
        if (_squareMetersController.text.isNotEmpty)
          _buildReviewItem('Size', '${_squareMetersController.text} m²'),
        
        if (_parkingSpacesController.text.isNotEmpty)
          _buildReviewItem('Parking', '${_parkingSpacesController.text} space(s)'),
        
        if (_yearBuiltController.text.isNotEmpty)
          _buildReviewItem('Year Built', _yearBuiltController.text),
        
        _buildReviewItem('Furnishing', _furnishingStatus.toUpperCase()),
        _buildReviewItem('Address', _addressController.text),
        _buildReviewItem('Location', '${_cityAreaController.text}, ${_stateController.text}'),
        
        const Divider(height: 32),
        
        _buildReviewItem('Images', '${_selectedImages.length} image(s)'),
        if (_selectedVideo != null)
          _buildReviewItem('Video', '1 video added'),
        
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You can save as draft to continue editing later, or publish to make it live.',
                  style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
                ),
              ),
            ],
          ),
        ),
      ],
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
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}