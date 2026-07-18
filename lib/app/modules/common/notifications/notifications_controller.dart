import 'package:get/get.dart';

import '../../../services/api_service.dart';
import '../../../../config/app_config.dart';
import '../../../widgets/app_feedback.dart';

class AppNotificationsController extends GetxController {
  final _apiService = Get.find<ApiService>();

  final isLoading = false.obs;
  final notifications = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    isLoading.value = true;
    try {
      final response = await _apiService.get<dynamic>(
        '${AppConfig.baseUrl}/Notifications/unread',
        fromJson: (json) => json,
      );

      if (response.success && response.data is List) {
        notifications.value = (response.data as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else {
        notifications.clear();
      }
    } catch (e) {
      notifications.clear();
      AppFeedback.error('Error', 'Failed to load notifications');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAllRead() async {
    try {
      final response = await _apiService.patch<dynamic>(
        '${AppConfig.baseUrl}/Notifications/read-all',
        data: const {},
        fromJson: (json) => json,
      );

      if (response.success) {
        AppFeedback.success('Done', 'All notifications marked as read');
        await loadNotifications();
      } else {
        AppFeedback.error('Error', response.message);
      }
    } catch (e) {
      AppFeedback.error('Error', 'Failed to update notifications');
    }
  }

  Future<void> markRead(int id) async {
    try {
      final response = await _apiService.patch<dynamic>(
        '${AppConfig.baseUrl}/Notifications/$id/read',
        data: const {},
        fromJson: (json) => json,
      );

      if (response.success) {
        await loadNotifications();
      }
    } catch (e) {
      AppFeedback.error('Error', 'Failed to mark notification as read');
    }
  }

  Future<void> handleNotificationTap(Map<String, dynamic> item) async {
    final id = int.tryParse((item['id'] ?? item['Id'] ?? '').toString());
    if (id != null) {
      await markRead(id);
    }

    final entityType =
        (item['relatedEntityType'] ?? item['RelatedEntityType'])?.toString();
    final entityId =
        (item['relatedEntityId'] ?? item['RelatedEntityId'])?.toString();

    if (entityType != null && entityId != null) {
      if (entityType.toLowerCase() == 'appointment') {
        Get.toNamed('/appointment-detail',
            arguments: {'appointmentId': entityId});
      }
      // Add other entity types as needed
    }
  }

  String displayTitle(Map<String, dynamic> item) {
    return (item['title'] ?? item['Title'] ?? 'Notification').toString();
  }

  String displayMessage(Map<String, dynamic> item) {
    return (item['message'] ?? item['Message'] ?? '').toString();
  }

  String displayMeta(Map<String, dynamic> item) {
    final type = (item['type'] ?? item['Type'] ?? '').toString();
    final createdAt = (item['createdAt'] ?? item['CreatedAt'] ?? '').toString();
    final parts = <String>[];
    if (type.isNotEmpty) parts.add(type);
    if (createdAt.isNotEmpty) parts.add(createdAt);
    return parts.join(' • ');
  }
}
