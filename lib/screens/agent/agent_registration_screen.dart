import 'package:flutter/material.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/services/supabase_service.dart';

class AgentRegistrationScreen extends StatefulWidget {
  const AgentRegistrationScreen({super.key});

  @override
  State<AgentRegistrationScreen> createState() => _AgentRegistrationScreenState();
}

class _AgentRegistrationScreenState extends State<AgentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _yearsOfExperienceController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _agencyIdController = TextEditingController();
  
  bool _isLoading = false;
  bool _hasAgencyAffiliation = false;
  final List<String> _selectedSpecializations = [];
  
  final List<String> _availableSpecializations = [
    'Residential Sales',
    'Commercial Sales',
    'Residential Rentals',
    'Commercial Rentals',
    'Property Management',
    'Investment Properties',
    'Luxury Properties',
    'Land Sales',
  ];

  @override
  void dispose() {
    _displayNameController.dispose();
    _licenseNumberController.dispose();
    _yearsOfExperienceController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    _agencyIdController.dispose();
    super.dispose();
  }

  Future<void> _handleAgentRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSpecializations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one specialization'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = SupabaseService().getCurrentUser();
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Create agent record
      await SupabaseService().client.from('agents').insert({
        'profile_id': user.id,
        'agency_id': _hasAgencyAffiliation && _agencyIdController.text.isNotEmpty 
            ? _agencyIdController.text 
            : null,
        'display_name': _displayNameController.text.trim(),
        'license_number': _licenseNumberController.text.trim(),
        'years_of_experience': int.parse(_yearsOfExperienceController.text),
        'specialization': _selectedSpecializations,
        'bio': _bioController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'verified': false,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agent registration submitted successfully! Our team will verify your account.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
        
        // Navigate to agent dashboard
        Navigator.pushReplacementNamed(context, AppRoutes.agentDashboard);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
            backgroundColor: Colors.red,
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
        title: const Text('Register as Agent'),
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
                  'Agent Registration',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Provide your professional details to get started',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),
                
                // Professional Information
                const Text(
                  'Professional Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _displayNameController,
                  decoration: InputDecoration(
                    labelText: 'Display Name *',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your display name';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _licenseNumberController,
                  decoration: InputDecoration(
                    labelText: 'License Number *',
                    prefixIcon: const Icon(Icons.badge),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your license number';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _yearsOfExperienceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Years of Experience *',
                    prefixIcon: const Icon(Icons.work),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter years of experience';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _bioController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Professional Bio *',
                    alignLabelWithHint: true,
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your bio';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Specializations
                const Text(
                  'Specializations *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableSpecializations.map((spec) {
                    final isSelected = _selectedSpecializations.contains(spec);
                    return FilterChip(
                      label: Text(spec),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSpecializations.add(spec);
                          } else {
                            _selectedSpecializations.remove(spec);
                          }
                        });
                      },
                      selectedColor: AppColors.primaryColor.withValues(alpha: 0.3),
                      checkmarkColor: AppColors.primaryColor,
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 30),
                
                // Contact Information
                const Text(
                  'Contact Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _phoneController,
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
                
                TextFormField(
                  controller: _emailController,
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
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _whatsappController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'WhatsApp Number (Optional)',
                    prefixIcon: const Icon(Icons.chat),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Agency Affiliation
                const Text(
                  'Agency Affiliation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                
                SwitchListTile(
                  title: const Text('I am affiliated with an agency'),
                  value: _hasAgencyAffiliation,
                  onChanged: (value) {
                    setState(() {
                      _hasAgencyAffiliation = value;
                    });
                  },
                  activeThumbColor: AppColors.primaryColor,
                ),
                
                if (_hasAgencyAffiliation) ...[
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _agencyIdController,
                    decoration: InputDecoration(
                      labelText: 'Agency ID (Optional)',
                      prefixIcon: const Icon(Icons.business),
                      helperText: 'Enter your agency ID if you have one',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 30),
                
                // Register Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleAgentRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Text(
                            'Register as Agent',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Back to Role Selection'),
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