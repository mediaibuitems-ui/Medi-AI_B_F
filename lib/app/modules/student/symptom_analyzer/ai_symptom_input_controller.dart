import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medi_ai/app/services/api_service.dart';

class AiSymptomInputController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // Step Management
  final currentStep = 0.obs;
  final int totalSteps = 4;
  final List<GlobalKey<FormState>> formKeys = [
    GlobalKey<FormState>(), // Step 0: Demographics
    GlobalKey<FormState>(), // Step 1: Red Flags
    GlobalKey<FormState>(), // Step 2: Symptoms
    GlobalKey<FormState>(), // Step 3: Context
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

  // State - Step 2: Symptoms
  final selectedSymptoms = <String>[].obs;
  final selectedSeverity = ''.obs;
  final onset = ''.obs;
  final durationController = TextEditingController();
  final otherSymptomsController = TextEditingController();

  final List<String> commonSymptoms = [
    'Fever', 'Cough', 'Headache', 'Fatigue', 'Sore Throat',
    'Body Aches', 'Nausea', 'Dizziness', 'Shortness of Breath', 'Chest Pain'
  ];
  final List<String> severityLevels = ['Mild', 'Moderate', 'Severe'];
  final List<String> onsetOptions = ['Sudden', 'Gradual'];

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

  void toggleSymptom(String symptom) {
    if (selectedSymptoms.contains(symptom)) {
      selectedSymptoms.remove(symptom);
    } else {
      selectedSymptoms.add(symptom);
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

    // Step 2 validation
    if (currentStep.value == 2) {
      if (selectedSymptoms.isEmpty && otherSymptomsController.text.trim().isEmpty) {
        Get.snackbar('Input Required', 'Please select or enter at least one symptom.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade100);
        return;
      }
      if (selectedSeverity.value.isEmpty || onset.value.isEmpty) {
        Get.snackbar('Input Required', 'Please select severity and onset.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade100);
        return;
      }
    }

    if (currentStep.value < totalSteps - 1) {
      currentStep.value++;
    } else {
      analyzeSymptoms();
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  Future<void> analyzeSymptoms() async {
    isLoading.value = true;
    try {
      final requestData = {
        'age': int.tryParse(ageController.text.trim()),
        'biologicalSex': biologicalSex.value,
        'pregnancyStatus': pregnancyStatus.value,
        'redFlags': selectedRedFlags.toList(),
        'selectedSymptoms': selectedSymptoms.toList(),
        'otherSymptoms': otherSymptomsController.text.trim(),
        'severity': selectedSeverity.value,
        'onset': onset.value,
        'duration': durationController.text.trim(),
        'existingConditions': existingConditionsController.text.trim().isNotEmpty ? [existingConditionsController.text.trim()] : [],
        'currentMedications': currentMedicationsController.text.trim(),
        'allergies': allergiesController.text.trim(),
      };

      final response = await _apiService.post('/analyzer/evaluate', data: requestData);

      if (response.success && response.data != null) {
        // We might get an emergency response from server if it caught keywords
        if (response.data is Map && response.data['isEmergency'] == true) {
           Get.offNamed('/emergency-guidance');
        } else {
           Get.offNamed('/symptom-analyzer-result', arguments: response.data);
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
    durationController.dispose();
    otherSymptomsController.dispose();
    existingConditionsController.dispose();
    currentMedicationsController.dispose();
    allergiesController.dispose();
    super.onClose();
  }
}
