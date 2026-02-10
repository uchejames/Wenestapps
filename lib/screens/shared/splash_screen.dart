import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _taglineFade;
  late Animation<double> _taglineSlide;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
      ),
    );

    _taglineSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _shimmer = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final supabaseService = SupabaseService();
    final user = supabaseService.getCurrentUser();

    if (user != null) {
      try {
        final profile = await supabaseService.getProfile(user.id);
        if (profile != null) {
          final route = await supabaseService.getDashboardRoute(user.id);
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, route);
        } else {
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        debugPrint('Error fetching profile: $e');
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      final hasSelectedLanguage = prefs.containsKey('language_code');

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        hasSelectedLanguage ? '/onboarding' : '/language_onboarding',
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.darkTeal,
                AppColors.primaryColor,
                AppColors.lightTeal,
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                children: [
                  // Animated background circles
                  Positioned(
                    top: -100,
                    right: -100,
                    child: Opacity(
                      opacity: 0.05,
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -150,
                    left: -150,
                    child: Opacity(
                      opacity: 0.05,
                      child: Container(
                        width: 400,
                        height: 400,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  // Main content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo with animated rings
                        FadeTransition(
                          opacity: _logoFade,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer ring
                                Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.secondaryColor.withValues(alpha: 0.2),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                // Middle ring
                                Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.accentColor.withValues(alpha: 0.3),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                // Inner circle with logo
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.accentColor.withValues(alpha: 0.3),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/images/splash.png',
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 50),

                        // App name with shimmer effect
                        FadeTransition(
                          opacity: _taglineFade,
                          child: Transform.translate(
                            offset: Offset(0, _taglineSlide.value),
                            child: Column(
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) {
                                    return LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: const [
                                        Colors.white,
                                        AppColors.accentColor,
                                        Colors.white,
                                      ],
                                      stops: [
                                        _shimmer.value - 0.3,
                                        _shimmer.value,
                                        _shimmer.value + 0.3,
                                      ],
                                    ).createShader(bounds);
                                  },
                                  child: const Text(
                                    AppStrings.appName,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 3.0,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  AppStrings.appTagline,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 80),

                        // Loading indicator
                        FadeTransition(
                          opacity: _taglineFade,
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.accentColor.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}