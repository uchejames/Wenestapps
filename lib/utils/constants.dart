import 'package:flutter/material.dart';

class AppColors {
  // Updated WeNest Brand Colors from logo
  static const Color primaryColor = Color(0xFF0A3F3F);      // Dark teal from logo
  static const Color secondaryColor = Color(0xFFC9A961);    // Gold from logo
  static const Color accentColor = Color(0xFFD4AF37);       // Bright gold accent
  static const Color backgroundColor = Color(0xFFF5F5F5);    // Light background
  static const Color textColor = Color(0xFF212121);          // Dark text
  static const Color errorColor = Color(0xFFD32F2F);         // Error red
  static const Color lightTeal = Color(0xFF1A5F5F);          // Lighter teal for gradients
  static const Color darkTeal = Color(0xFF062828);           // Darker teal
}

class AppStrings {
  static const String appName = 'WeNest';
  static const String appTagline = 'Nest Where it feels right';
}

class AppRoutes {
  // Core routes
  static const String splash = '/';
  static const String languageOnboarding = '/language_onboarding';
  static const String onboarding = '/onboarding';
  
  // Auth routes
  static const String login = '/login';
  static const String signup = '/signup';
  static const String roleSelection = '/role_selection';
  static const String forgotPassword = '/forgot_password';
  
  // Legal routes
  static const String termsAndConditions = '/terms_and_conditions';
  static const String privacyPolicy = '/privacy_policy';
  
  // Settings routes
  static const String settings = '/settings';
  static const String helpSupport = '/help_support';
  static const String faq = '/faq';
  static const String languageSelection = '/language_selection';
  
  // User routes
  static const String userHome = '/user_home';
  static const String userSearch = '/user_search';
  static const String userAgencies = '/user_agencies';
  static const String userMessages = '/user_messages';
  static const String userProfile = '/user_profile';
  
  // Agency routes
  static const String agencyRegistration = '/agency_registration';
  static const String agencyDashboard = '/agency_dashboard';
  
  // Landlord routes
  static const String landlordRegistration = '/landlord_registration';
  static const String landlordDashboard = '/landlord_dashboard';
  
  // Admin routes
  static const String adminLogin = '/admin_login';
  static const String adminDashboard = '/admin_dashboard';
  
  // Notification routes
  static const String notifications = '/notifications';
  static const String notificationsDetails = '/notifications_details';
  static const String notificationsSettings = '/notifications_settings';
}

enum UserType {
  user,
  agent,          // Regular agent
  agencyAdmin,    // Agency administrator
  landlord,
  admin
}

class UserTypeHelper {
  static String userTypeToString(UserType type) {
    switch (type) {
      case UserType.user:
        return 'user';
      case UserType.agent:
        return 'agent';
      case UserType.agencyAdmin:
        return 'agency_admin';
      case UserType.landlord:
        return 'landlord';
      case UserType.admin:
        return 'admin';
    }
  }
  
  static UserType? stringToUserType(String? type) {
    if (type == null) return null;
    switch (type.toLowerCase()) {
      case 'user':
        return UserType.user;
      case 'agent':
        return UserType.agent;
      case 'agency_admin':
        return UserType.agencyAdmin;
      case 'landlord':
        return UserType.landlord;
      case 'admin':
        return UserType.admin;
      default:
        return null;
    }
  }
}

// Asset paths for images
class AppAssets {
  // Logo assets
  static const String logo = 'assets/images/logo.png';
  static const String logoWhite = 'assets/images/logo_white.png';
  static const String logoIcon = 'assets/images/logo_icon.png';
  
  // Onboarding images
  static const String onboarding1 = 'assets/images/onboarding1.png';
  static const String onboarding2 = 'assets/images/onboarding2.png';
  static const String onboarding3 = 'assets/images/onboarding3.png';
  
  // Background images
  static const String heroBg = 'assets/images/hero_bg.jpg';
  
  // Placeholder images
  static const String propertyPlaceholder = 'assets/images/property_placeholder.png';
  static const String avatarPlaceholder = 'assets/images/avatar_placeholder.png';
}