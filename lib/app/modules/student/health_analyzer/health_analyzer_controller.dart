import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medi_ai/app/services/api_service.dart';
import 'package:medi_ai/config/app_config.dart';

class HealthAssessmentModel {
  final String triageLevel;
  final String analysis;
  final String? suggestedOtcMedicine;
  final List<String> homeCareProcedure;
  final String? doctorRecommendation;

  HealthAssessmentModel({
    required this.triageLevel,
    required this.analysis,
    this.suggestedOtcMedicine,
    required this.homeCareProcedure,
    this.doctorRecommendation,
  });

  factory HealthAssessmentModel.fromJson(Map<String, dynamic> json) {
    return HealthAssessmentModel(
      triageLevel: json['triageLevel'] ?? 'ROUTINE',
      analysis: json['clinicalAnalysis'] ?? json['analysis'] ?? '',
      suggestedOtcMedicine: json['suggestedMedicine'] ?? json['suggestedOtcMedicine'],
      homeCareProcedure: (json['homeCarePlan'] != null && json['homeCarePlan'] is String)
          ? List<String>.from(jsonDecode(json['homeCarePlan']))
          : (json['homeCareProcedure'] != null ? List<String>.from(json['homeCareProcedure']) : []),
      doctorRecommendation: json['recommendedDoctor'] ?? json['doctorRecommendation'],
    );
  }
}

class HealthAnalyzerController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final TextEditingController symptomController = TextEditingController();

  final RxBool isLoading = false.obs;
  final Rx<HealthAssessmentModel?> assessment = Rx<HealthAssessmentModel?>(null);

  Future<void> analyzeSymptoms() async {
    final text = symptomController.text.trim();
    if (text.isEmpty) {
      Get.snackbar('Error', 'Please enter your symptoms.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isLoading.value = true;
    assessment.value = null;

    try {
      final response = await _apiService.post(
        '${AppConfig.baseUrl}/healthanalyzer/assess',
        data: {'Symptoms': text},
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        assessment.value = HealthAssessmentModel.fromJson(response.data);
      } else {
        Get.snackbar('Analysis Failed', response.message, 
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to connect to the analysis engine.', 
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    symptomController.dispose();
    super.onClose();
  }
}
