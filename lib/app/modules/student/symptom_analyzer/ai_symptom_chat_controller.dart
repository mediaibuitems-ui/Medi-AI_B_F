import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medi_ai/app/services/api_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class AiSymptomChatController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  late String sessionId;
  
  final messages = <ChatMessage>[].obs;
  final answerController = TextEditingController();
  final isLoading = false.obs;
  final questionCount = 1.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is Map) {
      sessionId = args['sessionId'];
      messages.add(ChatMessage(text: args['question'], isUser: false));
    } else {
      Get.snackbar('Error', 'Invalid session data.');
      Get.back();
    }
  }

  Future<void> sendAnswer() async {
    final answer = answerController.text.trim();
    if (answer.isEmpty) return;

    messages.add(ChatMessage(text: answer, isUser: true));
    answerController.clear();
    isLoading.value = true;

    try {
      final response = await _apiService.post('/analyzer/interview/answer', data: {
        'sessionId': sessionId,
        'answer': answer,
      });

      if (response.success && response.data != null) {
        final data = response.data;
        if (data['isEmergency'] == true) {
          Get.offNamed('/emergency-guidance');
        } else if (data['action'] == 'complete') {
          // Interview complete, navigate to results
          Get.offNamed('/symptom-analyzer-result', arguments: data);
        } else if (data['action'] == 'ask') {
          messages.add(ChatMessage(text: data['question'], isUser: false));
          questionCount.value++;
        }
      } else {
        Get.snackbar('Error', response.message ?? 'Failed to send answer',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100);
      }
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    answerController.dispose();
    super.onClose();
  }
}
