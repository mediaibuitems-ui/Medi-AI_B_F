import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/system_settings_model.dart';
import '../../../services/api_service.dart';
import 'package:medi_ai/app/widgets/app_feedback.dart';

class SystemSettingsController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // Observables matching the model
  final maintenanceMode = false.obs;
  final emailNotifications = true.obs;
  final smsNotifications = false.obs;
  final autoApproveRegistrations = false.obs;
  final requireEmailVerification = true.obs;
  final twoFactorAuth = false.obs;
  final sessionTimeout = 30.obs;
  final maxLoginAttempts = 5.obs;

  // Text Controllers
  late TextEditingController systemNameController;
  late TextEditingController emailController;
  late TextEditingController supportEmailController;

  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    systemNameController = TextEditingController();
    emailController = TextEditingController();
    supportEmailController = TextEditingController();
    loadSettings();
  }

  @override
  void onClose() {
    systemNameController.dispose();
    emailController.dispose();
    supportEmailController.dispose();
    super.onClose();
  }

  Future<void> loadSettings() async {
    isLoading.value = true;
    try {
      final response = await _apiService.get<SystemSettingsModel>(
        '/admin/system-settings',
        fromJson: (json) => SystemSettingsModel.fromJson(json),
      );

      if (response.success && response.data != null) {
        final settings = response.data!;
        maintenanceMode.value = settings.maintenanceMode;
        emailNotifications.value = settings.emailNotifications;
        smsNotifications.value = settings.smsNotifications;
        autoApproveRegistrations.value = settings.autoApproveRegistrations;
        requireEmailVerification.value = settings.requireEmailVerification;
        twoFactorAuth.value = settings.twoFactorAuth;
        sessionTimeout.value = settings.sessionTimeoutMinutes;
        maxLoginAttempts.value = settings.maxLoginAttempts;

        systemNameController.text = settings.systemName;
        emailController.text = settings.contactEmail;
        supportEmailController.text = settings.supportEmail;
      }
    } catch (e) {
      AppFeedback.error('Error', 'Failed to load settings: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveSettings() async {
    isLoading.value = true;
    final model = SystemSettingsModel(
      maintenanceMode: maintenanceMode.value,
      emailNotifications: emailNotifications.value,
      smsNotifications: smsNotifications.value,
      autoApproveRegistrations: autoApproveRegistrations.value,
      requireEmailVerification: requireEmailVerification.value,
      twoFactorAuth: twoFactorAuth.value,
      sessionTimeoutMinutes: sessionTimeout.value,
      maxLoginAttempts: maxLoginAttempts.value,
      systemName: systemNameController.text,
      contactEmail: emailController.text,
      supportEmail: supportEmailController.text,
    );

    try {
      final response = await _apiService.put<SystemSettingsModel>(
        '/admin/system-settings',
        data: model.toJson(),
        fromJson: (json) => SystemSettingsModel.fromJson(json),
      );

      if (response.success) {
        AppFeedback.success('Success', 'System settings saved successfully');
      } else {
        AppFeedback.error('Error', response.message);
      }
    } catch (e) {
      AppFeedback.error('Error', 'Failed to save settings: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> backupDatabase() async {
    isLoading.value = true;
    try {
      final response =
          await _apiService.post<dynamic>('/admin/backup-database');

      if (response.success) {
        AppFeedback.success('Backup Started', response.message);
      } else {
        AppFeedback.error('Error', response.message);
      }
    } catch (e) {
      AppFeedback.error('Error', 'Failed to contact backup service: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> clearCache() async {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear cache'),
        content: Text(
          'This will clear all cached data. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              isLoading.value = true;
              try {
                final response =
                    await _apiService.post<dynamic>('/admin/clear-cache');

                if (response.success) {
                  AppFeedback.success('Success', response.message);
                } else {
                  AppFeedback.error('Error', response.message);
                }
              } catch (e) {
                AppFeedback.error('Error', 'Failed to clear cache: $e');
              } finally {
                isLoading.value = false;
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
