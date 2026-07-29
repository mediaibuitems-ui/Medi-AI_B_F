import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medi_ai/app/services/api_service.dart';

class AiSymptomInputController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // Step Management
  final currentStep = 0.obs;
  final int totalSteps = 3;
  final List<GlobalKey<FormState>> formKeys = [
    GlobalKey<FormState>(), // Step 0: Demographics
    GlobalKey<FormState>(), // Step 1: Red Flags
    GlobalKey<FormState>(), // Step 2: Context
  ];

  // State - Step 0: Demographics
  final ageController = TextEditingController();
  final biologicalSex = ''.obs;
  final pregnancyStatus = RxnString();

  // State - Step 1: Red Flags
  final selectedRedFlags = <String>[].obs;
  final List<String> redFlagsOptions = [
    'Chest pain or pressure',
    'Difficulty breathing',
    'Severe bleeding',
    'Sudden confusion or loss of consciousness',
    'Stroke-like symptoms',
    'Thoughts of self-harm'
  ];



  // State - Step 3: Medical Context
  final existingConditionsController = TextEditingController();
  final currentMedicationsController = TextEditingController();
  final allergiesController = TextEditingController();

  final isLoading = false.obs;

  void toggleRedFlag(String flag) {
    if (selectedRedFlags.contains(flag)) {
      selectedRedFlags.remove(flag);
    } else {
      selectedRedFlags.add(flag);
    }
  }



  void nextStep() {
    if (!formKeys[currentStep.value].currentState!.validate()) {
      return;
    }

    // Step 0 validation for sex
    if (currentStep.value == 0 && biologicalSex.value.isEmpty) {
      Get.snackbar('Input Required', 'Please select your biological sex.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade100);
      return;
    }

    // Step 1: Red Flags Gate
    if (currentStep.value == 1 && selectedRedFlags.isNotEmpty) {
      Get.offNamed('/emergency-guidance');
      return;
    }

    if (currentStep.value < totalSteps - 1) {
      currentStep.value++;
    } else {
      startInterview();
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  Future<void> startInterview() async {
    isLoading.value = true;
    try {
      final requestData = {
        'age': int.tryParse(ageController.text.trim()),
        'biologicalSex': biologicalSex.value,
        'pregnancyStatus': pregnancyStatus.value,
        'redFlags': selectedRedFlags.toList(),
        'existingConditions': existingConditionsController.text.trim().isNotEmpty ? [existingConditionsController.text.trim()] : [],
        'currentMedications': currentMedicationsController.text.trim(),
        'allergies': allergiesController.text.trim(),
      };

      final response = await _apiService.post('/analyzer/interview/start', data: requestData);

      if (response.success && response.data != null) {
        if (response.data is Map && response.data['isEmergency'] == true) {
           Get.offNamed('/emergency-guidance');
        } else {
           Get.offNamed('/symptom-analyzer-chat', arguments: response.data);
        }
      } else {
        Get.snackbar('Analysis Failed', response.message ?? 'Unknown error',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100);
      }
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    ageController.dispose();
    existingConditionsController.dispose();
    currentMedicationsController.dispose();
    allergiesController.dispose();
    super.onClose();
  }
}
