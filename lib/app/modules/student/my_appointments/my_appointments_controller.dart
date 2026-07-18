import 'dart:async';
import 'package:get/get.dart';
import '../../../data/models/appointment.dart';
import '../../../services/auth_service.dart';
import '../../../services/doctor_service.dart';
import 'package:medi_ai/config/app_config.dart';
import '../../../services/api_service.dart';
import '../../../services/appointment_event_service.dart' as import_event;

class MyAppointmentsController extends GetxController {
  final _authService = Get.find<AuthService>();
  final _apiService =
      Get.find<ApiService>(); // For student calls if service missing
  DoctorService? _doctorService;

  final RxList<Appointment> appointments = <Appointment>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  StreamSubscription? _appointmentSub;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<DoctorService>()) {
      _doctorService = Get.find<DoctorService>();
    }
    loadAppointments();

    if (Get.isRegistered<import_event.AppointmentEventService>()) {
      _appointmentSub = Get.find<import_event.AppointmentEventService>().stream.listen((event) {
        if (event.action == 'refresh' || event.action == 'created' || event.action == 'cancelled') {
          loadAppointments();
        }
      });
    }
  }

  @override
  void onClose() {
    _appointmentSub?.cancel();
    super.onClose();
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

  Future<void> cancelAppointment(String id) async {
    try {
      final response = await _apiService.delete('${AppConfig.baseUrl}/Appointments/$id');
      if (response.success) {
        // Find and update the appointment in the list (soft cancel)
        final index = appointments.indexWhere((a) => a.id == id);
        if (index != -1) {
          final apt = appointments[index];
          appointments[index] = Appointment(
            id: apt.id,
            patientId: apt.patientId,
            patientName: apt.patientName,
            doctorId: apt.doctorId,
            doctorName: apt.doctorName,
            specialization: apt.specialization,
            dateTime: apt.dateTime,
            status: 'Cancelled',
            symptoms: apt.symptoms,
            notes: apt.notes,
            prescription: apt.prescription,
            createdAt: apt.createdAt,
          );
        }
        
        // Fire event to update dashboard
        if (Get.isRegistered<import_event.AppointmentEventService>()) {
          Get.find<import_event.AppointmentEventService>().emit(import_event.AppointmentEvent(id.toString(), 'cancelled'));
        } else {
          Get.put(import_event.AppointmentEventService()).emit(import_event.AppointmentEvent(id.toString(), 'cancelled'));
        }
      } else {
        Get.snackbar('Error', response.message, snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to cancel appointment: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }
}
