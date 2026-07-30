import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medi_ai/app/services/api_service.dart';

class AiSymptomInputController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // State
  final selectedSymptoms = <String>[].obs;
  final selectedSeverity = ''.obs;
  final durationController = TextEditingController();
  final additionalContextController = TextEditingController();
  final isLoading = false.obs;
  final error = ''.obs;

  final List<String> commonSymptoms = [
    'Fever',
    'Cough',
    'Headache',
    'Fatigue',
    'Sore Throat',
    'Body Aches',
    'Nausea',
    'Dizziness',
    'Shortness of Breath',
    'Chest Pain'
  ];

  final List<String> severityLevels = ['Mild', 'Moderate', 'Severe'];

  void toggleSymptom(String symptom) {
    if (selectedSymptoms.contains(symptom)) {
      selectedSymptoms.remove(symptom);
    } else {
      selectedSymptoms.add(symptom);
    }
  }

  void selectSeverity(String severity) {
    selectedSeverity.value = severity;
  }

  Future<void> analyzeSymptoms() async {
    if (selectedSymptoms.isEmpty) {
      Get.snackbar(
          'Input Required', 'Please select at least one symptom.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100);
      return;
    }

    isLoading.value = true;
    error.value = '';
    try {
      final requestData = {
        'symptoms': selectedSymptoms.toList(),
        'severity': selectedSeverity.value,
        'duration': durationController.text.trim(),
        'additionalContext': additionalContextController.text.trim(),
      };

      final response = await _apiService.post('/analyzer/evaluate', data: requestData);

      if (response.success && response.data != null) {
        Get.toNamed('/symptom-analyzer-result', arguments: response.data);
      } else {
        error.value = response.message ?? 'Unknown error';
      }
    } catch (e) {
      error.value = 'An unexpected error occurred. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    durationController.dispose();
    additionalContextController.dispose();
    super.onClose();
  }
}
