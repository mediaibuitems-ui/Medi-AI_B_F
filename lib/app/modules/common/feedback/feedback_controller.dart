import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../config/app_config.dart';
import '../../../services/api_service.dart';
import '../../../widgets/app_feedback.dart';

class FeedbackController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final subjectController = TextEditingController();
  final messageController = TextEditingController();

  final isSubmitting = false.obs;
  final isLoadingHistory = false.obs;
  final feedbackHistory = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadMyFeedback();
  }

  @override
  void onClose() {
    subjectController.dispose();
    messageController.dispose();
    super.onClose();
  }

  Future<void> submitFeedback() async {
    final subject = subjectController.text.trim();
    final message = messageController.text.trim();

    if (subject.isEmpty || message.isEmpty) {
      AppFeedback.error('Error', 'Please fill in both subject and message.');
      return;
    }

    isSubmitting.value = true;
    try {
      final response = await _apiService.post<dynamic>(
        '${AppConfig.baseUrl}/Feedback',
        data: {
          'Subject': subject,
          'Message': message,
        },
        requiresAuth: true,
      );

      if (response.success) {
        subjectController.clear();
        messageController.clear();
        AppFeedback.success(
            'Submitted',
            response.message.isEmpty
                ? 'Your feedback has been submitted successfully.'
                : response.message);
        await loadMyFeedback();
      } else {
        AppFeedback.error(
            'Error',
            response.message.isEmpty
                ? 'Unable to submit feedback.'
                : response.message);
      }
    } catch (e) {
      AppFeedback.error('Error', 'Failed to submit feedback.');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> loadMyFeedback() async {
    isLoadingHistory.value = true;
    try {
      final response = await _apiService.get<dynamic>(
        '${AppConfig.baseUrl}/Feedback/my-feedback',
      );

      if (response.success && response.data is List) {
        feedbackHistory.value = (response.data as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else {
        feedbackHistory.clear();
      }
    } catch (e) {
      feedbackHistory.clear();
    } finally {
      isLoadingHistory.value = false;
    }
  }

  bool isResponded(Map<String, dynamic> item) {
    final status = _readString(item, ['status', 'Status']).toLowerCase();
    return status == 'responded';
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
    final status = _readString(item, ['status', 'Status'], fallback: 'Pending');
    return status.isEmpty ? 'Pending' : status;
  }

  String readCreatedAt(Map<String, dynamic> item) {
    return _readString(
        item, ['createdAt', 'CreatedAt', 'submittedAt', 'SubmittedAt']);
  }

  String readUserName(Map<String, dynamic> item) {
    return _readString(
        item, ['userName', 'UserName', 'fullName', 'FullName', 'name', 'Name'],
        fallback: 'User');
  }

  String readUserRole(Map<String, dynamic> item) {
    return _readString(item, ['role', 'Role', 'userRole', 'UserRole'],
        fallback: 'Student');
  }

  String readTargetId(Map<String, dynamic> item) {
    return _readString(item, ['id', 'Id'], fallback: '');
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
