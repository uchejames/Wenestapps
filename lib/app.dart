import 'package:flutter/material.dart';
import 'package:wenest/utils/constants.dart';

// Core Screens
import 'screens/shared/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/onboarding/language_onboarding_screen.dart';

// Authentication Screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/auth/forgot_password_screen.dart';

// Legal Screens
import 'screens/legal/terms_and_conditions_screen.dart';
import 'screens/legal/privacy_policy_screen.dart';

// Settings & Support Screens
import 'screens/shared/settings_screen.dart';
import 'screens/shared/help_support_screen.dart';
import 'screens/shared/faq_screen.dart';
import 'screens/shared/language_selection_screen.dart';

// User Screens
import 'screens/user/user_home_screen.dart';
import 'screens/user/user_search_screen.dart';
import 'screens/user/user_agencies_screen.dart';
import 'screens/user/user_messages_screen.dart';
import 'screens/user/user_profile_screen.dart';

// Agency Screens
import 'screens/agency/agency_registration_screen.dart';
import 'screens/agency/agency_dashboard_screen.dart';

// Landlord Screens
import 'screens/landlord/landlord_registration_screen.dart';
import 'screens/landlord/landlord_dashboard_screen.dart';


// Shared Screens - Notifications
import 'screens/shared/notifications_screen.dart';
import 'screens/shared/notifications_details_screen.dart';
import 'screens/shared/notifications_settings_screen.dart';


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,

      // ============ THEME CONFIGURATION ============
      theme: ThemeData(
        primaryColor: AppColors.primaryColor,
        fontFamily: 'OpenSans',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryColor,
          primary: AppColors.primaryColor,
          secondary: AppColors.secondaryColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(width: 0.50, color: Color(0xFFD1D1D6)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(width: 0.50, color: Color(0xFFD1D1D6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primaryColor, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),

      // ============ ROUTING CONFIGURATION ============
      initialRoute: '/',
      routes: {
        // ============ CORE APP ROUTES ============
        '/': (context) => const SplashScreen(),
        '/language_onboarding': (context) => const LanguageOnboardingScreen(),
        '/onboarding': (context) => const OnboardingScreen(),

        // ============ AUTHENTICATION ROUTES ============
        '/role_selection': (context) => const RoleSelectionScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),

        // ============ LEGAL ROUTES ============
        '/terms_and_conditions': (context) => const TermsAndConditionsScreen(),
        '/privacy_policy': (context) => const PrivacyPolicyScreen(),

        // ============ SETTINGS & SUPPORT ROUTES ============
        '/settings': (context) => const SettingsScreen(),
        '/help_support': (context) => const HelpSupportScreen(),
        '/faq': (context) => const FAQScreen(),
        '/language_selection': (context) => const LanguageSelectionScreen(),

        // ============ USER ROUTES ============
        '/user_home': (context) => const UserHomeScreen(),
        '/user_search': (context) => const UserSearchScreen(),
        '/user_agencies': (context) => const UserAgenciesScreen(),
        '/user_messages': (context) => const UserMessagesScreen(),
        '/user_profile': (context) => const UserProfileScreen(),

        // ============ AGENCY ROUTES ============
        '/agency_registration': (context) => const AgencyRegistrationScreen(),
        '/agency_dashboard': (context) => const AgencyDashboardScreen(),

        // ============ LANDLORD ROUTES ============
        '/landlord_registration': (context) =>
            const LandlordRegistrationScreen(),
        '/landlord_dashboard': (context) => const LandlordDashboardScreen(),

        // ============ NOTIFICATION ROUTES ============
        '/notifications': (context) => const NotificationsScreen(),
        '/notifications_details': (context) =>
            const NotificationsDetailsScreen(),
        '/notifications_settings': (context) =>
            const NotificationsSettingsScreen(),
      },
    );
  }
}