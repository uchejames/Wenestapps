import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable edge-to-edge mode for modern look
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Make system bars transparent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Supabase
  try {
    await SupabaseService.initialize();
    print('Supabase initialized successfully');
  } catch (e) {
    print('Error initializing Supabase: $e');
  }

  runApp(const MyApp());
}