import 'package:get/get.dart';
import 'dart:async';

import '../../../routes/app_routes.dart';
import '../../../services/storage_service.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/medicine_reminder_service.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    // Start loading data the millisecond the splash screen appears
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 1. Start a 2.5 second timer. We want the user to see your logo!
      final minimumSplashTime =
          Future.delayed(const Duration(milliseconds: 2500));

      // 2. Load all your services in the background while the timer counts down
      Get.put(await StorageService().init(), permanent: true);
      Get.put(await ApiService().init(), permanent: true);

      final authService = await AuthService().init();
      Get.put(authService, permanent: true);

      final notificationService = await NotificationService().init();
      Get.put(notificationService, permanent: true);
      Get.put(await MedicineReminderService().init(), permanent: true);

      // Reschedule any saved medicine reminders from offline storage
      // This ensures reminders work after device reboot or app restart
      await notificationService.rescheduleSavedReminders();

      // 3. Make sure the 2.5 seconds have actually passed before we move on
      await minimumSplashTime;

      // 4. Check the cache to see if they are logged in
      if (authService.isAuthenticated.value &&
          authService.currentUser.value != null) {
        final user = authService.currentUser.value!;

        // Route them to the correct dashboard based on role
        if (user.isDoctor) {
          Get.offAllNamed(AppRoutes.doctorDashboard);
        } else if (user.isFaculty) {
          Get.offAllNamed(AppRoutes.facultyDashboard);
        } else if (user.isAdmin) {
          Get.offAllNamed(AppRoutes.adminDashboard);
        } else {
          Get.offAllNamed(AppRoutes.studentDashboard);
        }
      } else {
        // If they aren't logged in, send them to Login
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (e) {
      print('Error in splash: $e');
      // Safety net: If anything crashes, just send them to login
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
