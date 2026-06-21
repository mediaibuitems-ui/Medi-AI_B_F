import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medi_ai/config/app_config.dart';
import 'package:medi_ai/app/services/api_service.dart';

class SymptomCheckerController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final symptomsController = TextEditingController();
  final selectedSymptoms = <String>[].obs;
  final severityOptions = const ['Mild', 'Moderate', 'Severe'];
  final durationOptions = const [
    'Less than a day',
    '1-3 days',
    '1 week',
    'More than a week',
  ];
  final selectedSeverity = 'Moderate'.obs;
  final selectedDuration = '1-3 days'.obs;
  final isAnalyzing = false.obs;
  final isLoadingHistory = false.obs;
  // Using a map to simplify frontend binding, but could be a typed model
  final analysisResult = Rx<Map<String, dynamic>?>(null);
  final historyItems = <Map<String, dynamic>>[].obs;

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
    'Chest Pain',
  ];

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  @override
  void onClose() {
    symptomsController.dispose();
    super.onClose();
  }

  void toggleSymptom(String symptom) {
    if (selectedSymptoms.contains(symptom)) {
      selectedSymptoms.remove(symptom);
    } else {
      selectedSymptoms.add(symptom);
    }
  }

  void setSeverity(String severity) {
    if (severityOptions.contains(severity)) {
      selectedSeverity.value = severity;
    }
  }

  void setDuration(String duration) {
    if (durationOptions.contains(duration)) {
      selectedDuration.value = duration;
    }
  }

  Future<void> analyzeSymptoms() async {
    if (selectedSymptoms.isEmpty && symptomsController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please select or describe your symptoms',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isAnalyzing.value = true;
    analysisResult.value = null;

    try {
      final response = await _apiService.post<dynamic>(
        '${AppConfig.baseUrl}/ai/analyze',
        data: {
          'SelectedSymptoms': selectedSymptoms.toList(),
          'AdditionalDescription': symptomsController.text.trim(),
          'Question': symptomsController.text.trim(),
          'Severity': selectedSeverity.value,
          'Duration': selectedDuration.value,
        },
        requiresAuth: true,
      );

      if (response.success && response.data != null) {

      await loadHistory();
        final data = response.data as Map<String, dynamic>;
        // Map backend response to frontend structure.
        // Handle both PascalCase (C# Default) and camelCase (JSON Default) keys
        analysisResult.value = {
          'condition': data['condition']?.toString() ??
              data['Condition']?.toString() ??
              'Unknown',
          'confidence':
              '${_parseConfidence(data['confidence'] ?? data['Confidence'])}%',
          'severity': data['severity']?.toString() ??
              data['Severity']?.toString() ??
              'Unknown',
          'recommendations':
              _parseList(data['recommendations'] ?? data['Recommendations']),
          'whenToSeeDoctor':
              _parseList(data['warningSigns'] ?? data['WarningSigns']),
        };
      } else {
        Get.snackbar(
          'Error',
          response.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isAnalyzing.value = false;
    }
  }

  Future<void> loadHistory() async {
    isLoadingHistory.value = true;
    try {
      final response = await _apiService.get<List<dynamic>>(
        '${AppConfig.baseUrl}/ai/history',
      );

      if (response.success && response.data is List) {
        historyItems.value = (response.data as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    } catch (e) {
      historyItems.clear();
    } finally {
      isLoadingHistory.value = false;
    }
  }

  String _parseConfidence(dynamic value) {
    if (value == null) return "0";
    if (value is num) return value.toStringAsFixed(0);
    if (value is String) {
      return (double.tryParse(value) ?? 0).toStringAsFixed(0);
    }
    return "0";
  }

  List<String> _parseList(dynamic list) {
    if (list is List) {
      return list.map((e) => e.toString()).toList();
    }
    return [];
  }
}
