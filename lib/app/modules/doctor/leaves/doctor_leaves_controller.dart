import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../config/app_theme.dart';
import '../../../services/doctor_service.dart';
import 'package:intl/intl.dart';

class DoctorLeavesController extends GetxController {
  final _doctorService = Get.find<DoctorService>();

  final leaves = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLeaves();
  }

  Future<void> fetchLeaves() async {
    try {
      isLoading.value = true;
      final response = await _doctorService.getMyLeaves();
      if (response.success && response.data != null) {
        leaves.assignAll(response.data!);
      } else {
        Get.snackbar(
          'Error',
          response.message ?? 'Failed to load leaves',
          backgroundColor: AppTheme.error.withOpacity(0.1),
          colorText: AppTheme.error,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred while loading leaves',
        backgroundColor: AppTheme.error.withOpacity(0.1),
        colorText: AppTheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addLeave(
      DateTime startDate, DateTime endDate, String reason) async {
    try {
      final data = {
        'startDate': DateFormat('yyyy-MM-dd').format(startDate),
        'endDate': DateFormat('yyyy-MM-dd').format(endDate),
        'reason': reason,
      };

      final response = await _doctorService.addLeave(data);
      if (response.success) {
        Get.snackbar(
          'Success',
          'Leave added successfully',
          backgroundColor: AppTheme.success.withOpacity(0.1),
          colorText: AppTheme.success,
        );
        fetchLeaves(); // Refresh the list
      } else {
        Get.snackbar(
          'Error',
          response.message ?? 'Failed to add leave',
          backgroundColor: AppTheme.error.withOpacity(0.1),
          colorText: AppTheme.error,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred while adding leave',
        backgroundColor: AppTheme.error.withOpacity(0.1),
        colorText: AppTheme.error,
      );
    }
  }

  Future<void> updateLeave(
      int id, DateTime startDate, DateTime endDate, String reason) async {
    try {
      final data = {
        'startDate': DateFormat('yyyy-MM-dd').format(startDate),
        'endDate': DateFormat('yyyy-MM-dd').format(endDate),
        'reason': reason,
      };

      final response = await _doctorService.updateLeave(id, data);
      if (response.success) {
        Get.snackbar(
          'Success',
          'Leave updated successfully',
          backgroundColor: AppTheme.success.withOpacity(0.1),
          colorText: AppTheme.success,
        );
        fetchLeaves(); // Refresh the list
      } else {
        Get.snackbar(
          'Error',
          response.message ?? 'Failed to update leave',
          backgroundColor: AppTheme.error.withOpacity(0.1),
          colorText: AppTheme.error,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred while updating leave',
        backgroundColor: AppTheme.error.withOpacity(0.1),
        colorText: AppTheme.error,
      );
    }
  }

  Future<void> deleteLeave(int id) async {
    try {
      final response = await _doctorService.deleteLeave(id);
      if (response.success) {
        Get.snackbar(
          'Success',
          'Leave deleted successfully',
          backgroundColor: AppTheme.success.withOpacity(0.1),
          colorText: AppTheme.success,
        );
        fetchLeaves(); // Refresh the list
      } else {
        Get.snackbar(
          'Error',
          response.message ?? 'Failed to delete leave',
          backgroundColor: AppTheme.error.withOpacity(0.1),
          colorText: AppTheme.error,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred while deleting leave',
        backgroundColor: AppTheme.error.withOpacity(0.1),
        colorText: AppTheme.error,
      );
    }
  }
}
