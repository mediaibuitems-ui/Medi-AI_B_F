import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medi_ai/config/app_config.dart';
import 'package:medi_ai/app/data/models/medical_history.dart';
import 'package:medi_ai/app/services/api_service.dart';

class MedicalHistoryController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final medicalHistoryList = <MedicalHistory>[].obs;
  final isLoading = true.obs;

  // Form Controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final notesController = TextEditingController();
  final recordType = 'Allergy'.obs;
  final diagnosisDate = Rx<DateTime?>(null);

  final List<String> recordTypes = [
    'Allergy',
    'Chronic Condition',
    'Surgery',
    'Previous Illness',
    'Immunization',
    'Other'
  ];

  @override
  void onInit() {
    super.onInit();
    fetchMedicalHistory();
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    notesController.dispose();
    super.onClose();
  }

  Future<void> fetchMedicalHistory() async {
    isLoading.value = true;
    try {
      final response = await _apiService.get<List<dynamic>>(
        '${AppConfig.baseUrl}/MedicalHistory',
      );

      if (response.success && response.data != null) {
        medicalHistoryList.value =
            response.data!.map((e) => MedicalHistory.fromJson(e)).toList();
      } else {
        Get.snackbar('Error', response.message);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load medical history: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addMedicalHistory() async {
    if (titleController.text.isEmpty) {
      Get.snackbar('Error', 'Title is required');
      return;
    }

    try {
      final data = {
        'RecordType': recordType.value,
        'Title': titleController.text,
        'Description': descriptionController.text,
        'Notes': notesController.text,
        'DiagnosisDate': diagnosisDate.value?.toIso8601String(),
      };

      final response = await _apiService.post<dynamic>(
        '${AppConfig.baseUrl}/MedicalHistory',
        data: data,
      );

      if (response.success) {
        Get.back(); // Close dialog
        Get.snackbar('Success', 'Medical history added successfully');
        _clearForm();
        fetchMedicalHistory();
      } else {
        Get.snackbar('Error', response.message);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to add record: $e');
    }
  }

  Future<void> deleteMedicalHistory(int id) async {
    try {
      final response = await _apiService
          .delete<dynamic>('${AppConfig.baseUrl}/MedicalHistory/$id');
      if (response.success) {
        Get.snackbar('Success', 'Record deleted');
        fetchMedicalHistory();
      } else {
        Get.snackbar('Error', response.message);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete record: $e');
    }
  }

  void _clearForm() {
    titleController.clear();
    descriptionController.clear();
    notesController.clear();
    recordType.value = 'Allergy';
    diagnosisDate.value = null;
  }
}
