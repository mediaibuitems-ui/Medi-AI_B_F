import 'package:get/get.dart';
import 'package:medi_ai/app/data/models/appointment.dart';
import 'package:medi_ai/app/services/api_service.dart';

class AdminAppointmentsController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final RxList<Appointment> allAppointments = <Appointment>[].obs;
  final RxList<Appointment> filteredAppointments = <Appointment>[].obs;
  final RxBool isLoading = true.obs;

  final RxString selectedFilter = 'All'.obs;
  final List<String> filterOptions = [
    'All',
    'Pending',
    'Confirmed',
    'Completed',
    'Cancelled'
  ];

  @override
  void onInit() {
    super.onInit();
    loadAppointments();
  }

  Future<void> loadAppointments() async {
    isLoading.value = true;
    try {
      final response = await _apiService.get('/Appointments');
      if (response.success && response.data != null) {
        final List<dynamic> list = response.data;
        allAppointments.value =
            list.map((json) => Appointment.fromJson(json)).toList();
        _applyFilter();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load appointments');
    } finally {
      isLoading.value = false;
    }
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
    _applyFilter();
  }

  void _applyFilter() {
    if (selectedFilter.value == 'All') {
      filteredAppointments.value = allAppointments;
    } else {
      filteredAppointments.value = allAppointments
          .where((a) => a.status == selectedFilter.value)
          .toList();
    }
  }

  void viewAppointmentDetails(Appointment appointment) {
    Get.toNamed('/appointment-detail', arguments: {'appointment': appointment});
  }

  Future<void> deleteAppointment(String id) async {
    try {
      final response = await _apiService.delete('/Appointments/$id');
      if (response.success) {
        Get.snackbar('Success', 'Appointment deleted/cancelled successfully');
        await loadAppointments();
      } else {
        Get.snackbar('Error', response.message);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete appointment');
    }
  }
}
