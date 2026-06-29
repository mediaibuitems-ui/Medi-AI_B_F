import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medi_ai/config/app_config.dart';
import 'package:medi_ai/app/services/api_service.dart';
import 'package:medi_ai/app/services/auth_service.dart';

class SymptomCheckerController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final _authService = Get.find<AuthService>(); // Add auth service to get user name

  final textController = TextEditingController();
  final scrollController = ScrollController();
  
  final messages = <Map<String, String>>[].obs;
  final isAnalyzing = false.obs;
  
  // Form fields
  final customSymptomController = TextEditingController();
  final durationController = TextEditingController();
  final selectedSymptoms = <String>[].obs;
  
  final RxString userName = ''.obs;
  final RxBool isChatActive = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserAndGreet();
  }

  Future<void> _loadUserAndGreet() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      userName.value = user.name;
    }
    _setGreeting();
  }

  void _setGreeting() {
    final nameStr = userName.value.isNotEmpty ? " ${userName.value}" : "";
    messages.clear();
    messages.add({
      'role': 'assistant',
      'content': 'Welcome$nameStr! I am your AI Medical Assistant. Please use the form below to describe your symptoms and how long you have had them.'
    });
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    customSymptomController.dispose();
    durationController.dispose();
    super.onClose();
  }

  void resetChat() {
    customSymptomController.clear();
    durationController.clear();
    selectedSymptoms.clear();
    isChatActive.value = false;
    _setGreeting();
  }

  void toggleSymptom(String symptom) {
    if (selectedSymptoms.contains(symptom)) {
      selectedSymptoms.remove(symptom);
    } else {
      selectedSymptoms.add(symptom);
    }
  }

  void startAnalysis() {
    final custom = customSymptomController.text.trim();
    final duration = durationController.text.trim();
    
    List<String> allSymptoms = List.from(selectedSymptoms);
    if (custom.isNotEmpty) {
      allSymptoms.add(custom);
    }
    
    if (allSymptoms.isEmpty) {
      Get.snackbar('Required', 'Please select or enter at least one symptom');
      return;
    }
    if (duration.isEmpty) {
      Get.snackbar('Required', 'Please enter how many days you have had this issue');
      return;
    }

    final symptomsStr = allSymptoms.join(', ');
    final nameStr = userName.value.isNotEmpty ? "My name is ${userName.value}. " : "";
    
    final prompt = "${nameStr}I am experiencing the following symptoms: $symptomsStr. I have been facing this issue for $duration days. Please act as a medical triage AI and ask any relevant follow-up questions or suggest what I should do.";
    
    // We want the user bubble to look natural
    final displayPrompt = "I am experiencing: $symptomsStr.\nDuration: $duration days.";
    
    sendFormPrompt(prompt, displayPrompt);
  }

  Future<void> sendFormPrompt(String actualPrompt, String displayPrompt) async {
    if (isAnalyzing.value) return;

    // Transition to chat UI
    isChatActive.value = true;

    // Add user message for display
    messages.add({
      'role': 'user',
      'content': displayPrompt,
      'actual_prompt': actualPrompt // Store the hidden prompt to send to backend
    });
    
    scrollToBottom();
    isAnalyzing.value = true;

    await _hitBackend();
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

    await _hitBackend();
  }

  Future<void> _hitBackend() async {
    try {
      // Map the messages to send actual_prompt if it exists
      final messagesToSend = messages.map((m) => {
        'role': m['role'],
        'content': m.containsKey('actual_prompt') ? m['actual_prompt'] : m['content']
      }).toList();

      final response = await _apiService.post<dynamic>(
        '${AppConfig.baseUrl}/agent/chat',
        data: {
          'Messages': messagesToSend
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
