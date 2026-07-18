import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/doctor_service.dart';
import '../../../../config/app_theme.dart';
import '../dashboard/doctor_dashboard_controller.dart';

class WritePrescriptionController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final diagnosisController = TextEditingController();
  final notesController = TextEditingController();
  final medications = <Map<String, String>>[].obs;
  
  final _doctorService = Get.find<DoctorService>();
  
  String? appointmentId;
  String patientName = 'Patient';

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments is Map ? Map<String, dynamic>.from(Get.arguments as Map) : <String, dynamic>{};
    patientName = args['patientName'] ?? 'Patient';
    appointmentId = args['appointmentId']?.toString();
  }

  @override
  void onClose() {
    diagnosisController.dispose();
    notesController.dispose();
    super.onClose();
  }

  void addMedication(Map<String, String> med) {
    medications.add(med);
  }

  void removeMedication(int index) {
    medications.removeAt(index);
  }
  
  bool get hasUnsavedData {
    return diagnosisController.text.trim().isNotEmpty || medications.isNotEmpty || notesController.text.trim().isNotEmpty;
  }

  void savePrescription() {
    if (!formKey.currentState!.validate()) return;

    if (medications.isEmpty) {
      Get.snackbar(
        'Error',
        'Please add at least one medication',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.error,
        colorText: AppTheme.surface,
      );
      return;
    }

    if (appointmentId == null) {
      Get.snackbar('Error', 'Invalid appointment ID');
      return;
    }

    _doctorService
        .createStructuredPrescription(
      appointmentId: int.parse(appointmentId!),
      diagnosis: diagnosisController.text,
      notes: notesController.text,
      medicines: medications,
    )
        .then((response) async {
      if (response.success) {
        await _doctorService.updateAppointmentStatus(appointmentId!, 'Completed');
        Get.snackbar(
          'Success',
          'Prescription saved & Appointment Completed',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.success,
          colorText: AppTheme.surface,
        );
        
        // Clear data so PopScope doesn't warn
        diagnosisController.clear();
        medications.clear();
        notesController.clear();
        
        Future.delayed(const Duration(milliseconds: 500), () {
          Get.back();
          if (Get.isRegistered<DoctorDashboardController>()) {
            Get.find<DoctorDashboardController>().refresh();
          }
        });
      } else {
        Get.snackbar('Error', response.message);
      }
    }).catchError((e) {
      Get.snackbar('Error', 'Failed to save: $e');
    });
  }
}
