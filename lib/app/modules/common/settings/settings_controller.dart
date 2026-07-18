import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/storage_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/auth_service.dart';
import '../../../routes/app_routes.dart';

class SettingsController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();
  final NotificationService _notificationService =
      Get.find<NotificationService>();
  final AuthService _authService = Get.find<AuthService>();

  final RxBool isNotificationsMuted = false.obs;
  final RxBool pushNotifications = true.obs;
  final RxBool medicineReminders = true.obs;

  @override
  void onInit() {
    super.onInit();
    isNotificationsMuted.value = _storageService.isNotificationsMuted;
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    pushNotifications.value = prefs.getBool('pushNotifications') ?? true;
    medicineReminders.value = prefs.getBool('medicineReminders') ?? true;
  }

  Future<void> toggleNotifications(bool value) async {
    isNotificationsMuted.value = value;
    await _storageService.setNotificationsMuted(value);

    if (value) {
      await _notificationService.cancelAllNotifications();
      Get.snackbar('Settings updated', 'All local notifications muted',
          snackPosition: SnackPosition.BOTTOM);
    } else {
      await _notificationService.rescheduleSavedReminders();
      Get.snackbar('Settings updated', 'Local notifications unmuted',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> togglePushNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pushNotifications', value);
    pushNotifications.value = value;
    Get.snackbar(
      'Settings updated',
      value ? 'Push notifications enabled' : 'Push notifications disabled',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> toggleMedicineReminders(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('medicineReminders', value);
    medicineReminders.value = value;
    Get.snackbar(
      'Settings updated',
      value ? 'Medicine reminders enabled' : 'Medicine reminders disabled',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> contactDeveloper() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'mediaibuitems@gmail.com',
      query: 'subject=Medi-AI App Feedback',
    );
    try {
      if (!await launchUrl(emailLaunchUri)) {
        Get.snackbar('Error', 'Could not open email client',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not open email client',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void logout() {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _authService.logout();
              Get.offAllNamed(AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
