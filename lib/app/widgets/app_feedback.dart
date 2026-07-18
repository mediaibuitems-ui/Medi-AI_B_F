import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppFeedback {
  static void success(String title, String message) {
    _show(
      title: title,
      message: message,
      backgroundColor: const Color(0xFF22C55E), // Safe Green
      icon: Icons.check_circle_rounded,
    );
  }

  static void error(String title, String message) {
    _show(
      title: title,
      message: message,
      backgroundColor: const Color(0xFFEF4444), // Danger Red
      icon: Icons.error_rounded,
    );
  }

  static void warning(String title, String message) {
    _show(
      title: title,
      message: message,
      backgroundColor: const Color(0xFFF59E0B), // Warning Yellow/Amber
      icon: Icons.warning_rounded,
    );
  }

  static void info(String title, String message) {
    _show(
      title: title,
      message: message,
      backgroundColor: const Color(0xFF3B82F6), // Info Blue
      icon: Icons.info_rounded,
    );
  }

  static void _show({
    required String title,
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.snackbar(
      title,
      message,
      snackPosition:
          SnackPosition.TOP, // Top so gap is visible across all users
      snackStyle: SnackStyle.FLOATING,
      margin: const EdgeInsets.only(
          top: 24, left: 16, right: 16, bottom: 24), // Added a gap
      borderRadius: 16,
      colorText: Colors.white,
      backgroundColor: backgroundColor,
      icon: Icon(icon, color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      duration: const Duration(seconds: 3),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }
}
