import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../config/app_config.dart';
import '../../../services/api_service.dart';
import '../../../widgets/app_feedback.dart';

class ManageFeedbackController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final isLoading = false.obs;
  final isResponding = false.obs;
  final feedbackItems = <Map<String, dynamic>>[].obs;

  final responseController = TextEditingController();
  final RxnString activeFeedbackId = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadAllFeedback();
  }

  @override
  void onClose() {
    responseController.dispose();
    super.onClose();
  }

  Future<void> loadAllFeedback() async {
    isLoading.value = true;
    try {
      final response = await _apiService.get<dynamic>(
        '${AppConfig.baseUrl}/Feedback/admin/all',
      );

      if (response.success && response.data is List) {
        feedbackItems.value = (response.data as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else {
        feedbackItems.clear();
      }
    } catch (e) {
      feedbackItems.clear();
      AppFeedback.error('Error', 'Failed to load feedback items.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> respondToFeedback(String feedbackId, String responseText) async {
    final trimmed = responseText.trim();
    if (trimmed.isEmpty) {
      AppFeedback.error('Error', 'Please type a response before sending.');
      return;
    }

    isResponding.value = true;
    try {
      final response = await _apiService.put<dynamic>(
        '${AppConfig.baseUrl}/Feedback/admin/$feedbackId/respond',
        data: {
          'adminResponse': trimmed,
          'response': trimmed,
          'responseText': trimmed,
        },
      );

      if (response.success) {
        responseController.clear();
        activeFeedbackId.value = null;
        AppFeedback.success(
            'Done',
            response.message.isEmpty
                ? 'Reply sent successfully.'
                : response.message);
        await loadAllFeedback();
      } else {
        AppFeedback.error(
            'Error',
            response.message.isEmpty
                ? 'Unable to send reply.'
                : response.message);
      }
    } catch (e) {
      AppFeedback.error('Error', 'Failed to send reply.');
    } finally {
      isResponding.value = false;
    }
  }

  String readId(Map<String, dynamic> item) {
    return _readString(item, ['id', 'Id']);
  }

  String readUserName(Map<String, dynamic> item) {
    final userObj = item['user'] ?? item['User'];
    if (userObj != null && userObj is Map) {
      final name = userObj['name'] ??
          userObj['Name'] ??
          userObj['fullName'] ??
          userObj['FullName'];
      if (name != null && name.toString().trim().isNotEmpty)
        return name.toString();
    }
    return _readString(
        item, ['userName', 'UserName', 'fullName', 'FullName', 'name', 'Name'],
        fallback: 'Unknown User');
  }

  String readUserRole(Map<String, dynamic> item) {
    final userObj = item['user'] ?? item['User'];
    if (userObj != null && userObj is Map) {
      final role = userObj['role'] ?? userObj['Role'];
      if (role != null && role.toString().trim().isNotEmpty)
        return role.toString();
    }
    return _readString(item, ['role', 'Role', 'userRole', 'UserRole'],
        fallback: 'Student');
  }

  String readSubject(Map<String, dynamic> item) {
    return _readString(item, ['subject', 'Subject'], fallback: 'No subject');
  }

  String readMessage(Map<String, dynamic> item) {
    return _readString(item, ['message', 'Message'], fallback: '');
  }

  String readAdminResponse(Map<String, dynamic> item) {
    return _readString(
        item, ['adminResponse', 'AdminResponse', 'response', 'Response']);
  }

  String readStatus(Map<String, dynamic> item) {
    return _readString(item, ['status', 'Status'], fallback: 'Pending');
  }

  String readCreatedAt(Map<String, dynamic> item) {
    return _readString(
        item, ['createdAt', 'CreatedAt', 'submittedAt', 'SubmittedAt']);
  }

  bool isPending(Map<String, dynamic> item) {
    return readStatus(item).toLowerCase() == 'pending';
  }

  String _readString(Map<String, dynamic> item, List<String> keys,
      {String fallback = ''}) {
    for (final key in keys) {
      final value = item[key];
      if (value != null) {
        final text = value.toString().trim();
        if (text.isNotEmpty) {
          return text;
        }
      }
    }
    return fallback;
  }
}
