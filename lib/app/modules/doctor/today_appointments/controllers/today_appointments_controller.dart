import 'package:get/get.dart';
import '../../../../data/models/appointment.dart';
import '../../../../services/doctor_service.dart';
import '../../../../services/api_service.dart';
import '../../../../../config/app_config.dart';
import '../../dashboard/doctor_dashboard_controller.dart';

class TodayAppointmentsController extends GetxController {
  final _doctorService = Get.find<DoctorService>();
  final _apiService = Get.find<ApiService>();

  final RxList<Appointment> appointments = <Appointment>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAppointments();
  }

  Future<void> loadAppointments() async {
    isLoading.value = true;
    try {
      final response = await _doctorService.getTodayAppointments();
      if (response.success && response.data != null) {
        appointments.value = response.data!;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load appointments');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateStatus(String appointmentId, String newStatus) async {
    try {
      // Create a dedicated method in DoctorService or call API directly
      // Since DoctorService might not have this, we can use ApiService directly here or add to DoctorService
      // Using ApiService directly for speed, but ideally unrelated to clean architecture

      final response = await _apiService.put(
        '${AppConfig.baseUrl}/Appointments/$appointmentId/status',
        data: {'status': newStatus},
      );

      if (response.success) {
        Get.snackbar('Success', 'Appointment status updated');
        loadAppointments(); // Refresh list

        // Also refresh dashboard stats if possible
        if (Get.isRegistered<DoctorDashboardController>()) {
          Get.find<DoctorDashboardController>().loadDashboardData();
        }
      } else {
        Get.snackbar('error', response.message);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update appointment status');
    }
  }

  // NOTE: localized status helper removed — not referenced anywhere.
}
