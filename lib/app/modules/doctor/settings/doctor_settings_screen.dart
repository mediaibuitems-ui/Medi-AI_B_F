import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../config/app_theme.dart';
import 'doctor_settings_controller.dart';
import 'package:url_launcher/url_launcher.dart';

export 'doctor_settings_binding.dart';

class DoctorSettingsScreen extends GetView<DoctorSettingsController> {
  const DoctorSettingsScreen({super.key});

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'mediaibuitems@gmail.com',
      queryParameters: {
        'subject': 'Support Request - Doctor',
      },
    );
    try {
      await launchUrl(emailLaunchUri);
    } catch (e) {
      Get.snackbar('Error', 'Could not open email client');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Preferences
          const Text(
            'Preferences',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                Obx(() => SwitchListTile(
                      title: const Text('Mute Notifications'),
                      subtitle: const Text('Temporarily pause all alerts'),
                      value: controller.isNotificationsMuted.value,
                      onChanged: controller.setNotificationsMuted,
                      secondary: const Icon(Icons.notifications_off_outlined),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About
          const Text(
            'About',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About Medi-AI'),
                  subtitle: const Text('Version 1.0.0'),
                  onTap: () {
                    Get.dialog(
                      AlertDialog(
                        title: const Text('About Medi-AI'),
                        content: const Text(
                            'Medi-AI is a university clinic management system designed to streamline appointments, prescriptions, and health records.'),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.support_agent),
                  title: const Text('Contact Support'),
                  subtitle: const Text('mediaibuitems@gmail.com'),
                  onTap: _launchEmail,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Account
          const Text(
            'Account',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.error),
              title: const Text(
                'Log Out',
                style: TextStyle(color: AppTheme.error),
              ),
              onTap: () {
                Get.dialog(
                  AlertDialog(
                    title: const Text('Log Out'),
                    content: const Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Get.back();
                          controller.logout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Log Out'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
