import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medi_ai/config/app_config.dart';
import 'package:medi_ai/app/services/api_service.dart';

class SymptomCheckerController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final textController = TextEditingController();
  final scrollController = ScrollController();
  
  final messages = <Map<String, String>>[].obs;
  final isAnalyzing = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Start with a friendly greeting
    messages.add({
      'role': 'assistant',
      'content': 'Welcome! As your BUITEMS Medical Assistant, I am here to help students and faculty members. How can I help you today? Please describe your symptoms or request an action.'
    });
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void resetChat() {
    messages.clear();
    messages.add({
      'role': 'assistant',
      'content': 'Welcome! As your BUITEMS Medical Assistant, I am here to help students and faculty members. How can I help you today? Please describe your symptoms or request an action.'
    });
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void sendSuggestedPrompt(String prompt) {
    textController.text = prompt;
    sendMessage();
  }

  Future<void> sendMessage() async {
    final text = textController.text.trim();
    if (text.isEmpty || isAnalyzing.value) return;

    textController.clear();
    
    // Add user message
    messages.add({
      'role': 'user',
      'content': text
    });
    
    scrollToBottom();
    isAnalyzing.value = true;

    try {
      final response = await _apiService.post<dynamic>(
        '${AppConfig.baseUrl}/agent/chat',
        data: {
          'Messages': messages.toList()
        },
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        
        final replyText = data['reply']?.toString() ?? 
                          data['Reply']?.toString() ?? 
                          "No response generated.";
        
        messages.add({
          'role': 'assistant',
          'content': replyText,
        });
      } else {
        messages.add({
          'role': 'assistant',
          'content': 'Error: ${response.message}',
        });
      }
    } catch (e) {
      messages.add({
        'role': 'assistant',
        'content': 'An error occurred: $e',
      });
    } finally {
      isAnalyzing.value = false;
      scrollToBottom();
    }
  }
}
