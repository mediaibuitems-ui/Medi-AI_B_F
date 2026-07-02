import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medi_ai/app/services/api_service.dart';

class AiSymptomInputController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // State
  final selectedSymptoms = <String>[].obs;
  final selectedSeverity = ''.obs;
  final durationController = TextEditingController();
  final otherSymptomsController = TextEditingController();
  final isLoading = false.obs;
  final formKey = GlobalKey<FormState>();

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
    if (selectedSymptoms.isEmpty && otherSymptomsController.text.trim().isEmpty) {
      Get.snackbar('Input Required', 'Please select or enter at least one symptom.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade100);
      return;
    }
    if (selectedSeverity.value.isEmpty) {
      Get.snackbar('Input Required', 'Please select the severity.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade100);
      return;
    }
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;
    try {
      final requestData = {
        'selectedSymptoms': selectedSymptoms.toList(),
        'otherSymptoms': otherSymptomsController.text.trim(),
        'severity': selectedSeverity.value,
        'duration': durationController.text.trim(),
      };

      final response = await _apiService.post('/analyzer/evaluate', data: requestData);

      if (response.success && response.data != null) {
        Get.toNamed('/symptom-analyzer-result', arguments: response.data);
      } else {
        Get.snackbar('Analysis Failed', response.message, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade100);
      }
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred. Please try again.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade100);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    durationController.dispose();
    otherSymptomsController.dispose();
    super.onClose();
  }
}
