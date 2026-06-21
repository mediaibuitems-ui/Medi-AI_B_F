import 'package:get/get.dart';
import '../../../data/models/appointment.dart';
import '../../../services/auth_service.dart';
import '../../../services/doctor_service.dart';
import 'package:medi_ai/config/app_config.dart';
import '../../../services/api_service.dart';

class MyAppointmentsController extends GetxController {
  final _authService = Get.find<AuthService>();
  final _apiService =
      Get.find<ApiService>(); // For student calls if service missing
  DoctorService? _doctorService;

  final RxList<Appointment> appointments = <Appointment>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<DoctorService>()) {
      _doctorService = Get.find<DoctorService>();
    }
    loadAppointments();
  }

  Future<void> loadAppointments() async {
    isLoading.value = true;
    error.value = '';

    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        error.value = 'User not logged in';
        return;
      }

      if (user.role.toLowerCase() == 'doctor') {
        if (_doctorService == null) {
          if (Get.isRegistered<DoctorService>()) {
            _doctorService = Get.find<DoctorService>();
          } else {
            error.value = 'Doctor service unavailable';
            return;
          }
        }
        final response = await _doctorService!.getAllAppointments();
        if (response.success && response.data != null) {
          appointments.value = response.data!;
        } else {
          error.value = response.message;
        }
      } else {
        // Assume Student
        // If StudentService exists use it, otherwise call API directly
        final response = await _apiService.get<List<Appointment>>(
          '${AppConfig.baseUrl}/Appointments/my-appointments',
          fromJson: (json) {
            if (json is List) {
              return json.map((item) => Appointment.fromJson(item)).toList();
            }
            return [];
          },
        );
        if (response.success && response.data != null) {
          appointments.value = response.data!;
        } else {
          error.value = response.message;
        }
      }
    } catch (e) {
      error.value = 'Failed to load appointments: $e';
    } finally {
      isLoading.value = false;
    }
  }
}
