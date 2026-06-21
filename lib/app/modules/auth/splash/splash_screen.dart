import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../config/app_theme.dart';
import 'splash_controller.dart';
import '../../../../config/app_config.dart';

/// Splash screen shown while the app is loading services and deciding navigation.
class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override

  /// Builds the branded loading screen.
  Widget build(BuildContext context) {
    return Scaffold(
      // Use the brand primary color as the full-screen background.
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo centered at the top of the splash layout.
            Image.asset(
              'assets/images/logos/buitems-logo-png_seeklogo-273407.png',
              height: 150,
              width: 150,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    size: 64,
                    color: AppTheme.primary,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // App name shown in large white text.
            Text(
              AppConfig.appName,
              style: AppTheme.h1.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),

            // University/brand subtitle shown below the app name.
            Text(
              AppConfig.universityName,
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),

            // Circular progress indicator while startup work finishes.
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
