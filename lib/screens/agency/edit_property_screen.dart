import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/services/supabase_service.dart';
import 'package:wenest/models/agency.dart';
import 'package:wenest/models/property.dart';

class EditPropertyScreen extends StatefulWidget {
  final Property property;
  final Agency agency;

  const EditPropertyScreen({
    super.key,
    required this.property,
    required this.agency,
  });

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();
  
  // Controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _addressController;
  late TextEditingController _cityAreaController;
  late TextEditingController _stateController;
  late TextEditingController _bedroomsController;
  late TextEditingController _bathroomsController;
  late TextEditingController _toiletsController;
  late TextEditingController _squareMetersController;
  late TextEditingController _yearBuiltController;
  late TextEditingController _parkingSpacesController;
  
  late String _propertyType;
  late String _listingType;
  late String _furnishingStatus;
  late bool _negotiable;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _titleController = TextEditingController(text: widget.property.title);
    _descriptionController = TextEditingController(text: widget.property.description);
    _priceController = TextEditingController(text: widget.property.price.toStringAsFixed(0));
    _addressController = TextEditingController(text: widget.property.address);
    _cityAreaController = TextEditingController(text: widget.property.cityArea);
    _stateController = TextEditingController(text: widget.property.state);
    _bedroomsController = TextEditingController(text: widget.property.bedrooms?.toString() ?? '');
    _bathroomsController = TextEditingController(text: widget.property.bathrooms?.toString() ?? '');
    _toiletsController = TextEditingController(text: widget.property.toilets?.toString() ?? '');
    _squareMetersController = TextEditingController(text: widget.property.squareMeters?.toString() ?? '');
    _yearBuiltController = TextEditingController(text: widget.property.yearBuilt?.toString() ?? '');
    _parkingSpacesController = TextEditingController(text: widget.property.parkingSpaces.toString());
    
    _propertyType = widget.property.propertyType;
    _listingType = widget.property.listingType;
    _furnishingStatus = widget.property.furnishingStatus ?? 'unfurnished';
    _negotiable = widget.property.negotiable;
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
    super.dispose();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> _updateProperty() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill all required fields', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _supabaseService.updateProperty(
        propertyId: widget.property.id.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        propertyType: _propertyType,
        listingType: _listingType,
        price: double.parse(_priceController.text.trim()),
        address: _addressController.text.trim(),
        cityArea: _cityAreaController.text.trim(),
        state: _stateController.text.trim(),
        bedrooms: _bedroomsController.text.isEmpty ? null : int.parse(_bedroomsController.text),
        bathrooms: _bathroomsController.text.isEmpty ? null : int.parse(_bathroomsController.text),
        toilets: _toiletsController.text.isEmpty ? null : int.parse(_toiletsController.text),
        squareMeters: _squareMetersController.text.isEmpty ? null : double.parse(_squareMetersController.text),
        yearBuilt: _yearBuiltController.text.isEmpty ? null : int.parse(_yearBuiltController.text),
        furnishingStatus: _furnishingStatus,
        parkingSpaces: _parkingSpacesController.text.isEmpty ? 0 : int.parse(_parkingSpacesController.text),
        negotiable: _negotiable,
      );

      if (mounted) {
        _showSnackBar('Property updated successfully!', Colors.green);
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
        title: const Text('Edit Property'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildPropertyDetailsSection(),
              const SizedBox(height: 24),
              _buildLocationSection(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProperty,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Update Property', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Property Title *',
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

  Widget _buildPropertyDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Property Details',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
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

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Street Address *',
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
            prefixIcon: Icon(Icons.map_rounded),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }
}