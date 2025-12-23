import 'package:flutter/material.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/services/supabase_service.dart';

class AgencyRegistrationScreen extends StatefulWidget {
  const AgencyRegistrationScreen({super.key});

  @override
  State<AgencyRegistrationScreen> createState() => _AgencyRegistrationScreenState();
}

class _AgencyRegistrationScreenState extends State<AgencyRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _agencyNameController = TextEditingController();
  final _rcNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _officeAddressController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailAddressController = TextEditingController();
  final _websiteController = TextEditingController();
  bool _isLoading = false;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _agencyNameController.dispose();
    _rcNumberController.dispose();
    _descriptionController.dispose();
    _officeAddressController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _phoneNumberController.dispose();
    _emailAddressController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _handleAgencyRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms and Conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      final user = SupabaseService().getCurrentUser();
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Create agency in Supabase
      await SupabaseService().createAgency(
        profileId: user.id,
        name: _agencyNameController.text.trim(),
        registrationNumber: _rcNumberController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        contactEmail: _emailAddressController.text.trim(),
        contactPhone: _phoneNumberController.text.trim(),
        address: _officeAddressController.text.trim(),
        state: _stateController.text.trim().isEmpty 
            ? null 
            : _stateController.text.trim(),
        city: _cityController.text.trim().isEmpty 
            ? null 
            : _cityController.text.trim(),
        website: _websiteController.text.trim().isEmpty 
            ? null 
            : _websiteController.text.trim(),
      );
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agency registration submitted successfully! Our team will review and verify your account.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Navigate to agency dashboard
        Navigator.pushReplacementNamed(context, AppRoutes.agencyDashboard);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${error.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Your Agency'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agency Registration',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Please provide your agency details for verification',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),
                
                // Agency Information Section
                const Text(
                  'Agency Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                
                // Agency Name
                TextFormField(
                  controller: _agencyNameController,
                  decoration: InputDecoration(
                    labelText: 'Agency Name *',
                    prefixIcon: const Icon(Icons.business),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your agency name';
                    }
                    if (value.length < 3) {
                      return 'Agency name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 15),
                
                // RC Number
                TextFormField(
                  controller: _rcNumberController,
                  decoration: InputDecoration(
                    labelText: 'Registration Number (RC Number) *',
                    prefixIcon: const Icon(Icons.confirmation_number),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your registration number';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 15),
                
                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Agency Description (Optional)',
                    alignLabelWithHint: true,
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    hintText: 'Describe your agency and services...',
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // Office Address
                TextFormField(
                  controller: _officeAddressController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Office Address *',
                    alignLabelWithHint: true,
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your office address';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 15),
                
                // State
                TextFormField(
                  controller: _stateController,
                  decoration: InputDecoration(
                    labelText: 'State (Optional)',
                    prefixIcon: const Icon(Icons.map),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // City
                TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: 'City (Optional)',
                    prefixIcon: const Icon(Icons.location_city),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Contact Information Section
                const Text(
                  'Contact Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                
                // Phone Number
                TextFormField(
                  controller: _phoneNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number *',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 15),
                
                // Email Address
                TextFormField(
                  controller: _emailAddressController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address *',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email address';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 15),
                
                // Website
                TextFormField(
                  controller: _websiteController,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: 'Website (Optional)',
                    prefixIcon: const Icon(Icons.web),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    hintText: 'https://www.example.com',
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Terms and Conditions
                Row(
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      onChanged: (bool? value) {
                        setState(() {
                          _agreedToTerms = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _agreedToTerms = !_agreedToTerms;
                          });
                        },
                        child: const Text(
                          'I agree to the Terms and Conditions and Privacy Policy',
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Register Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleAgencyRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Register Agency',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Back button
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : () {
                      Navigator.pop(context);
                    },
                    child: const Text('← Back'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}