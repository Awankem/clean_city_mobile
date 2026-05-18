import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase — wrapped in try/catch so a missing
  // google-services.json does not crash the entire app.
  try {
    await Firebase.initializeApp();
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('⚠️ Firebase init failed: $e — continuing without notifications.');
  }

  // Check if user is already logged in
  final prefs = await SharedPreferences.getInstance();
  final hasToken = prefs.getString('auth_token') != null;

  runApp(
    ProviderScope(
      child: OverlaySupport.global(
        child: CleanCityApp(isAuthenticated: hasToken),
      ),
    ),
  );
}

class CleanCityApp extends StatelessWidget {
  final bool isAuthenticated;
  
  const CleanCityApp({super.key, required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CleanCity',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.createRouter(isAuthenticated),
    );
  }
}
