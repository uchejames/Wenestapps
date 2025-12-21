import 'package:flutter/material.dart';
import 'dart:async';
import 'package:wenest_app/services/supabase_service.dart';
import 'package:wenest_app/utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Simulate splash screen delay
    await Future.delayed(const Duration(seconds: 3));
    
    // Check if user is already logged in
    final user = SupabaseService().getCurrentUser();
    
    if (user != null) {
      // User is logged in, navigate to role selection screen
      Navigator.pushReplacementNamed(context, '/role_selection');
    } else {
      // User is not logged in, navigate to language onboarding screen
      Navigator.pushReplacementNamed(context, '/language_onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo placeholder - replace with actual logo
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.home_work,
                size: 80,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              AppStrings.appName,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              AppStrings.appTagline,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}