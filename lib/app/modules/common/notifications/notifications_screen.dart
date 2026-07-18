import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../config/app_theme.dart';
import 'notifications_controller.dart';

class NotificationsScreen extends GetView<AppNotificationsController> {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          Obx(() => TextButton(
                onPressed: controller.notifications.isEmpty
                    ? null
                    : controller.markAllRead,
                child: const Text(
                  'Mark all read',
                  style: TextStyle(color: Colors.white),
                ),
              )),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.notifications.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.loadNotifications,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Icon(Icons.notifications_none, size: 72, color: Colors.grey),
                SizedBox(height: 12),
                Center(child: Text('No unread notifications')),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadNotifications,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = controller.notifications[index];
              final id =
                  int.tryParse((item['id'] ?? item['Id'] ?? '').toString());
              final type =
                  (item['type'] ?? item['Type'] ?? '').toString().toLowerCase();
              final title = controller.displayTitle(item).toLowerCase();

              Color iconColor = AppTheme.primary;
              IconData iconData = Icons.notifications;

              if (type.contains('alert') ||
                  type.contains('danger') ||
                  title.contains('cancel') ||
                  title.contains('error') ||
                  title.contains('failed')) {
                iconColor = AppTheme.error;
                iconData = Icons.error_outline;
              } else if (type.contains('warning') ||
                  type.contains('system') ||
                  title.contains('pending') ||
                  title.contains('warning')) {
                iconColor = AppTheme.warning;
                iconData = Icons.warning_amber_rounded;
              } else if (type.contains('success') ||
                  title.contains('confirm') ||
                  title.contains('success') ||
                  title.contains('safe')) {
                iconColor = AppTheme.success;
                iconData = Icons.check_circle_outline;
              }

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: iconColor.withOpacity(0.1),
                    child: Icon(iconData, color: iconColor),
                  ),
                  title: Text(controller.displayTitle(item)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 4),
                      Text(controller.displayMessage(item)),
                      const SizedBox(height: 6),
                      if (controller.displayMeta(item).isNotEmpty)
                        Text(
                          controller.displayMeta(item),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  trailing: id == null
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.done_all),
                          onPressed: () => controller.markRead(id),
                        ),
                  onTap: () => controller.handleNotificationTap(item),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
