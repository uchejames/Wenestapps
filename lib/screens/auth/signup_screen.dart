import 'package:flutter/material.dart';
import 'package:wenest/services/supabase_service.dart';
import 'package:wenest/utils/constants.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  UserType? _selectedUserType;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is UserType) {
      _selectedUserType = args;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedUserType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a user type first'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await SupabaseService().signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        userType: UserTypeHelper.userTypeToString(_selectedUserType!),
      );

      if (mounted && response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Please check your email to verify your account.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
        
        _navigateBasedOnUserType(_selectedUserType!);
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateBasedOnUserType(UserType userType) {
    String route;
    switch (userType) {
      case UserType.user:
        route = AppRoutes.userHome;
        break;
      case UserType.agent:
        route = AppRoutes.agentRegistration;
        break;
      case UserType.agency:
        route = AppRoutes.agencyRegistration;
        break;
      case UserType.landlord:
        route = AppRoutes.landlordRegistration;
        break;
    }
    Navigator.pushReplacementNamed(context, route);
  }

  String _getUserTypeTitle() {
    if (_selectedUserType == null) return 'Create Account';
    return 'Create ${UserTypeHelper.getUserTypeDisplayName(_selectedUserType!)} Account';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryColor, AppColors.secondaryColor],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // WeNest Logo (replaced icon)
                      Image.asset(
                        'assets/images/splash.png', // Make sure this path matches your logo file
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),

                      // Tagline - made larger and more elegant
                      Text(
                        AppStrings.appTagline,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          letterSpacing: 1.8,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 50),

                      // Signup form card
                      Card(
                        elevation: 12,
                        shadowColor: Colors.black26,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(28.0),
                          child: Column(
                            children: [
                              Text(
                                _getUserTypeTitle(),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textColor,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Name field
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: const Icon(Icons.person),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please enter your full name';
                                  if (value.length < 3) return 'Name must be at least 3 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Email field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  prefixIcon: const Icon(Icons.email),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please enter your email';
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Please enter a valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Password field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please enter a password';
                                  if (value.length < 6) return 'Password must be at least 6 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Confirm Password
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  prefixIcon: const Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please confirm your password';
                                  if (value != _passwordController.text) return 'Passwords do not match';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 28),

                              // Sign Up button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleSignup,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 6,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : const Text(
                                          'Sign Up',
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              TextButton(
                                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.roleSelection),
                                child: const Text('← Change Role', style: TextStyle(fontSize: 16)),
                              ),
                              const SizedBox(height: 10),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("Already have an account? "),
                                  TextButton(
                                    onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                                    child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}