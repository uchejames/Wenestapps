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

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.8, curve: Curves.elasticOut),
      ),
    );

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _taglineSlide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
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
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryColor,      // 0xFF0A3F3F
                AppColors.darkTeal,          // 0xFF062828
              ],
            ),
          ),
          // Removed the duplicate SafeArea - now handled globally
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.18),
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/images/splash.png',
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    FadeTransition(
                      opacity: _taglineFade,
                      child: Transform.translate(
                        offset: Offset(0, _taglineSlide.value),
                        child: Text(
                          AppStrings.appTagline,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 2.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}