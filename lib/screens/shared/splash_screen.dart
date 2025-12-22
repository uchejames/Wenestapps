import 'package:flutter/material.dart';
import 'package:wenest/services/supabase_service.dart';
import 'package:wenest/utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // Check authentication and navigate
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for animation to complete
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Check if user is logged in
    final currentUser = SupabaseService().getCurrentUser();

    if (currentUser != null) {
      // User is logged in, get their type and navigate
      final userType = await SupabaseService().getUserType(currentUser.id);
      
      if (userType != null) {
        _navigateBasedOnUserType(userType);
      } else {
        // User has no type, go to role selection
        Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
      }
    } else {
      // User not logged in, go to language onboarding
      Navigator.pushReplacementNamed(context, AppRoutes.languageOnboarding);
    }
  }

  void _navigateBasedOnUserType(String userType) {
    final type = UserTypeHelper.stringToUserType(userType);
    
    switch (type) {
      case UserType.user:
        Navigator.pushReplacementNamed(context, AppRoutes.userHome);
        break;
      case UserType.agent:
        Navigator.pushReplacementNamed(context, AppRoutes.agencyDashboard);
        break;
      case UserType.agencyAdmin:
        Navigator.pushReplacementNamed(context, AppRoutes.agencyDashboard);
        break;
      case UserType.landlord:
        Navigator.pushReplacementNamed(context, AppRoutes.landlordDashboard);
        break;
      case UserType.admin:
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
        break;
      case null:
        Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
        break;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.darkTeal,
              AppColors.primaryColor,
              AppColors.lightTeal,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Image.asset(
                      AppAssets.logoWhite,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to icon if logo image not found
                        return const Icon(
                          Icons.home_work,
                          size: 120,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // App name
                  const Text(
                    AppStrings.appName,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Tagline
                  const Text(
                    AppStrings.appTagline,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  
                  const SizedBox(height: 50),
                  
                  // Loading indicator
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondaryColor),
                      strokeWidth: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}