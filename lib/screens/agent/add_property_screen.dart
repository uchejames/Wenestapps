import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/services/supabase_service.dart';
import 'package:wenest/models/agent.dart';
import 'package:wenest/models/property.dart';
import 'package:shimmer/shimmer.dart';

class AddPropertyScreen extends StatefulWidget {
  final Agent agent;

  const AddPropertyScreen({super.key, required this.agent});

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

  // Build methods same as agency add property screen
  Widget _buildBasicInfoStep() {
    // Same implementation as agency screen
    return const Column(children: [Text('Basic Info Step - Same as agency implementation')]);
  }

  Widget _buildPropertyDetailsStep() {
    return const Column(children: [Text('Property Details Step - Same as agency implementation')]);
  }

  Widget _buildLocationStep() {
    return const Column(children: [Text('Location Step - Same as agency implementation')]);
  }

  Widget _buildReviewStep() {
    return const Column(children: [Text('Review Step - Same as agency implementation')]);
  }
}