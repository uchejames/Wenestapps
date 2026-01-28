import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/services/supabase_service.dart';
import 'package:wenest/models/agency.dart';

class PropertyImageData {
  File file;
  bool isPrimary;
  
  PropertyImageData({required this.file, this.isPrimary = false});
}

class AddPropertyScreen extends StatefulWidget {
  final Agency agency;

  const AddPropertyScreen({super.key, required this.agency});

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

  // Image management
  final List<PropertyImageData> _images = [];
  int? _primaryImageIndex;
  bool _isUploadingImages = false;

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

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> selectedImages = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (selectedImages.isNotEmpty) {
        setState(() {
          for (var image in selectedImages) {
            _images.add(PropertyImageData(
              file: File(image.path),
              isPrimary: _images.isEmpty,
            ));
          }
          if (_primaryImageIndex == null && _images.isNotEmpty) {
            _primaryImageIndex = 0;
          }
        });
      }
    } catch (e) {
      _showSnackBar('Error selecting images: $e', Colors.red);
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (photo != null) {
        setState(() {
          _images.add(PropertyImageData(
            file: File(photo.path),
            isPrimary: _images.isEmpty,
          ));
          _primaryImageIndex ??= 0;
        });
      }
    } catch (e) {
      _showSnackBar('Error taking picture: $e', Colors.red);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      if (_primaryImageIndex == index) {
        _primaryImageIndex = _images.isNotEmpty ? 0 : null;
        if (_images.isNotEmpty) {
          _images[0].isPrimary = true;
        }
      } else if (_primaryImageIndex != null && _primaryImageIndex! > index) {
        _primaryImageIndex = _primaryImageIndex! - 1;
      }
    });
  }

  void _setPrimaryImage(int index) {
    setState(() {
      for (var img in _images) {
        img.isPrimary = false;
      }
      _images[index].isPrimary = true;
      _primaryImageIndex = index;
    });
  }

  Future<List<String>> _uploadImages(String propertyId) async {
    setState(() => _isUploadingImages = true);
    List<String> uploadedUrls = [];

    try {
      for (int i = 0; i < _images.length; i++) {
        final image = _images[i];
        final fileName = 'property_${propertyId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final filePath = '${widget.agency.id}/$propertyId/$fileName';

        await _supabaseService.client.storage
            .from('property-uploads')
            .upload(filePath, image.file);

        final url = _supabaseService.client.storage
            .from('property-uploads')
            .getPublicUrl(filePath);

        uploadedUrls.add(url);

        await _supabaseService.client.from('property_media').insert({
          'property_id': int.parse(propertyId),
          'file_url': url,
          'file_type': 'image',
          'display_order': i,
          'is_primary': image.isPrimary,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error uploading images: $e');
      rethrow;
    } finally {
      setState(() => _isUploadingImages = false);
    }

    return uploadedUrls;
  }

  Future<void> _submitProperty({bool publish = false}) async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill all required fields', Colors.orange);
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
        agencyId: widget.agency.id,
        bedrooms: _bedroomsController.text.isEmpty ? null : int.parse(_bedroomsController.text),
        bathrooms: _bathroomsController.text.isEmpty ? null : int.parse(_bathroomsController.text),
        toilets: _toiletsController.text.isEmpty ? null : int.parse(_toiletsController.text),
        squareMeters: _squareMetersController.text.isEmpty ? null : double.parse(_squareMetersController.text),
        yearBuilt: _yearBuiltController.text.isEmpty ? null : int.parse(_yearBuiltController.text),
        furnishingStatus: _furnishingStatus,
        parkingSpaces: _parkingSpacesController.text.isEmpty ? 0 : int.parse(_parkingSpacesController.text),
        negotiable: _negotiable,
      );

      if (_images.isNotEmpty) {
        await _uploadImages(propertyId);
      }

      if (publish) {
        await _supabaseService.publishProperty(propertyId);
      }

      if (mounted) {
        _showSnackBar(
          publish 
            ? 'Property published! It will be reviewed within 48 hours. It\'s live now but may be taken down if it doesn\'t meet our standards.' 
            : 'Property saved as draft!',
          Colors.green,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
            if (_currentStep < 4) {
              setState(() => _currentStep++);
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  if (_currentStep < 4)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Continue'),
                      ),
                    ),
                  if (_currentStep == 4) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => _submitProperty(publish: false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isLoading
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
                      onPressed: details.onStepCancel,
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
              title: const Text('Location'),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
              content: _buildLocationStep(),
            ),
            Step(
              title: const Text('Photos'),
              isActive: _currentStep >= 3,
              state: _currentStep > 3 ? StepState.complete : StepState.indexed,
              content: _buildPhotosStep(),
            ),
            Step(
              title: const Text('Review & Publish'),
              isActive: _currentStep >= 4,
              state: StepState.indexed,
              content: _buildReviewStep(),
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
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Property Title *',
            hintText: 'e.g., Modern 3 Bedroom Apartment',
            prefixIcon: Icon(Icons.title_rounded),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _descriptionController,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Description *',
            hintText: 'Describe the property features and amenities...',
            prefixIcon: Icon(Icons.description_rounded),
            alignLabelWithHint: true,
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16),
        
        DropdownButtonFormField<String>(
          initialValue: _propertyType,
          decoration: const InputDecoration(
            labelText: 'Property Type *',
            prefixIcon: Icon(Icons.home_rounded),
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
        const SizedBox(height: 16),
        
        DropdownButtonFormField<String>(
          initialValue: _listingType,
          decoration: const InputDecoration(
            labelText: 'Listing Type *',
            prefixIcon: Icon(Icons.sell_rounded),
          ),
          items: const [
            DropdownMenuItem(value: 'rent', child: Text('For Rent')),
            DropdownMenuItem(value: 'sale', child: Text('For Sale')),
            DropdownMenuItem(value: 'lease', child: Text('For Lease')),
            DropdownMenuItem(value: 'shortlet', child: Text('Shortlet')),
          ],
          onChanged: (value) => setState(() => _listingType = value!),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Price (₦) *',
            hintText: '0',
            prefixIcon: Icon(Icons.attach_money_rounded),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        
        CheckboxListTile(
          value: _negotiable,
          onChanged: (value) => setState(() => _negotiable = value!),
          title: const Text('Price is negotiable'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildPropertyDetailsStep() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _bedroomsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Bedrooms',
                  prefixIcon: Icon(Icons.bed_rounded),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _bathroomsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Bathrooms',
                  prefixIcon: Icon(Icons.bathtub_rounded),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _toiletsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Toilets',
                  prefixIcon: Icon(Icons.wc_rounded),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _parkingSpacesController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Parking',
                  prefixIcon: Icon(Icons.local_parking_rounded),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _squareMetersController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Size (m²)',
            prefixIcon: Icon(Icons.square_foot_rounded),
          ),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _yearBuiltController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Year Built',
            prefixIcon: Icon(Icons.calendar_today_rounded),
          ),
        ),
        const SizedBox(height: 16),
        
        DropdownButtonFormField<String>(
          initialValue: _furnishingStatus,
          decoration: const InputDecoration(
            labelText: 'Furnishing Status',
            prefixIcon: Icon(Icons.chair_rounded),
          ),
          items: const [
            DropdownMenuItem(value: 'unfurnished', child: Text('Unfurnished')),
            DropdownMenuItem(value: 'semi-furnished', child: Text('Semi-furnished')),
            DropdownMenuItem(value: 'fully-furnished', child: Text('Fully-furnished')),
          ],
          onChanged: (value) => setState(() => _furnishingStatus = value!),
        ),
      ],
    );
  }

  Widget _buildLocationStep() {
    return Column(
      children: [
        TextFormField(
          controller: _addressController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Street Address *',
            hintText: 'Enter full address',
            prefixIcon: Icon(Icons.home_rounded),
            alignLabelWithHint: true,
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _cityAreaController,
          decoration: const InputDecoration(
            labelText: 'City/Area *',
            hintText: 'e.g., Lekki, Ikeja',
            prefixIcon: Icon(Icons.location_city_rounded),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _stateController,
          decoration: const InputDecoration(
            labelText: 'State *',
            hintText: 'e.g., Lagos',
            prefixIcon: Icon(Icons.map_rounded),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  Widget _buildPhotosStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Add high-quality photos. The first image marked as primary will be the cover photo.',
                  style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Select Photos'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _takePicture,
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Take Photo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        if (_images.isEmpty)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid, width: 2),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('No photos added yet', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _images.length,
            itemBuilder: (context, index) {
              final image = _images[index];
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: image.isPrimary ? AppColors.primaryColor : Colors.grey.shade300,
                        width: image.isPrimary ? 3 : 1,
                      ),
                      image: DecorationImage(
                        image: FileImage(image.file),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (image.isPrimary)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PRIMARY',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Row(
                      children: [
                        if (!image.isPrimary)
                          GestureDetector(
                            onTap: () => _setPrimaryImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
                              ),
                              child: const Icon(Icons.star_border, size: 16, color: Colors.orange),
                            ),
                          ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
                            ),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        
        if (_images.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            '${_images.length} photo(s) selected',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewStep() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review Your Property',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildReviewItem('Title', _titleController.text),
          _buildReviewItem('Type', '$_propertyType - $_listingType'),
          _buildReviewItem('Price', '₦${_priceController.text}${_negotiable ? ' (Negotiable)' : ''}'),
          _buildReviewItem('Location', '${_cityAreaController.text}, ${_stateController.text}'),
          if (_bedroomsController.text.isNotEmpty)
            _buildReviewItem('Bedrooms', _bedroomsController.text),
          if (_bathroomsController.text.isNotEmpty)
            _buildReviewItem('Bathrooms', _bathroomsController.text),
          _buildReviewItem('Photos', '${_images.length} image(s)'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_rounded, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your property will go live immediately but will be reviewed within 48 hours. It may be taken down if it doesn\'t meet our standards.',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textColor),
            ),
          ),
        ],
      ),
    );
  }
}