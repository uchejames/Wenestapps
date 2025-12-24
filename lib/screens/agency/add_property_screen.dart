import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/services/supabase_service.dart';
import 'package:wenest/models/agency.dart';

class AddPropertyScreen extends StatefulWidget {
  final Agency agency;

  const AddPropertyScreen({super.key, required this.agency});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();
  
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
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
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
            if (_currentStep < 3) {
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
                  if (_currentStep < 3)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: details.onStepContinue,
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

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
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
        
        // Description
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
        
        // Property Type
        DropdownButtonFormField<String>(
          value: _propertyType,
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
        
        // Listing Type
        DropdownButtonFormField<String>(
          value: _listingType,
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
        
        // Price
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
        
        // Negotiable Checkbox
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
          value: _furnishingStatus,
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_rounded, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You can save as draft or publish directly. Published properties will be visible to users immediately.',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
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