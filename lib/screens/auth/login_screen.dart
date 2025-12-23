import 'package:flutter/material.dart';
import 'package:wenest/services/supabase_service.dart';
import 'package:wenest/utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await SupabaseService().signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted && response.user != null) {
        final route = await SupabaseService().getDashboardRoute(response.user!.id);
        Navigator.pushReplacementNamed(context, route);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${error.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                      // WeNest Logo
                      Image.asset(
                        'assets/images/splash.png', // Your golden logo
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),

                      // Larger, elegant tagline
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

                      // Login form card
                      Card(
                        elevation: 12,
                        shadowColor: Colors.black26,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(28.0),
                          child: Column(
                            children: [
                              const Text(
                                'Welcome Back',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 24),

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
                                  if (value == null || value.isEmpty) return 'Please enter your password';
                                  if (value.length < 6) return 'Password must be at least 6 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 28),

                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 6,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(height: 20),

                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                                child: const Text('Forgot Password?', style: TextStyle(fontSize: 16)),
                              ),
                              const SizedBox(height: 10),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("Don't have an account? "),
                                  TextButton(
                                    onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.signup),
                                    child: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold)),
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