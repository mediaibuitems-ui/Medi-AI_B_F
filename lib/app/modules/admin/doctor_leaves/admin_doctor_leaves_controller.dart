import 'package:get/get.dart';
import '../../../../config/app_theme.dart';
import '../../../services/api_service.dart';
import '../../../../config/app_config.dart';

class AdminDoctorLeavesController extends GetxController {
  final _apiService = Get.find<ApiService>();

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
      final response = await _apiService.get<List<dynamic>>(
        '${AppConfig.baseUrl}/Admin/doctor-leaves',
        fromJson: (json) {
          if (json is List) {
            return json
                .map((item) => item is Map<String, dynamic>
                    ? item
                    : Map<String, dynamic>.from(item as Map))
                .toList();
          }
          return [];
        },
      );

      if (response.success && response.data != null) {
        leaves.assignAll(response.data!.cast<Map<String, dynamic>>());
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

  Future<void> updateLeave(
      int id, DateTime startDate, DateTime endDate, String reason) async {
    try {
      final data = {
        'startDate': startDate.toIso8601String().split('T')[0],
        'endDate': endDate.toIso8601String().split('T')[0],
        'reason': reason,
      };

      final response = await _apiService.put<Object>(
        '${AppConfig.baseUrl}/Doctors/leaves/$id',
        data: data,
      );
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
      final response = await _apiService.delete<Object>(
        '${AppConfig.baseUrl}/Doctors/leaves/$id',
      );
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
