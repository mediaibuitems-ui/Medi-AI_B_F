import 'package:get/get.dart';
import '../data/models/api_response.dart';
import '../data/models/appointment.dart';
import '../data/models/medical_history.dart';
import '../services/api_service.dart';
import '../../config/app_config.dart';

class DoctorService extends GetxService {
  final _apiService = Get.find<ApiService>();

  // Get doctor's dashboard statistics
  Future<ApiResponse<Map<String, dynamic>>> getStatistics() async {
    return await _apiService.get<Map<String, dynamic>>(
      '${AppConfig.baseUrl}/Doctors/statistics',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // Get today's appointments for the doctor
  Future<ApiResponse<List<Appointment>>> getTodayAppointments() async {
    return await _apiService.get<List<Appointment>>(
      '${AppConfig.baseUrl}/Doctors/appointments/today',
      fromJson: (json) {
        if (json is List) {
          return json.map((item) => Appointment.fromJson(item)).toList();
        }
        return [];
      },
    );
  }

  // Get upcoming appointments for the doctor
  Future<ApiResponse<List<Appointment>>> getUpcomingAppointments() async {
    return await _apiService.get<List<Appointment>>(
      '${AppConfig.baseUrl}/Doctors/appointments/upcoming',
      fromJson: (json) {
        if (json is List) {
          return json.map((item) => Appointment.fromJson(item)).toList();
        }
        return [];
      },
    );
  }

  // Get all appointments for the doctor
  Future<ApiResponse<List<Appointment>>> getAllAppointments() async {
    return await _apiService.get<List<Appointment>>(
      '${AppConfig.baseUrl}/Doctors/appointments',
      fromJson: (json) {
        if (json is List) {
          return json.map((item) => Appointment.fromJson(item)).toList();
        }
        return [];
      },
    );
  }

  // Get doctor's patients
  Future<ApiResponse<List<Map<String, dynamic>>>> getPatients() async {
    return await _apiService.get<List<Map<String, dynamic>>>(
      '${AppConfig.baseUrl}/Doctors/patients',
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
  }

  // Get doctor's schedule
  Future<ApiResponse<List<Map<String, dynamic>>>> getMySchedule() async {
    return await _apiService.get<List<Map<String, dynamic>>>(
      '${AppConfig.baseUrl}/Doctors/my-schedule',
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
  }

  // Update schedule
  Future<ApiResponse<Object>> updateSchedule(
      List<Map<String, dynamic>> schedules) async {
    return await _apiService.post<Object>(
      '${AppConfig.baseUrl}/Doctors/schedule',
      data: {'schedules': schedules},
    );
  }

  // Get current doctor's booking settings
  Future<ApiResponse<Map<String, dynamic>>> getMyBookingSettings() async {
    return await _apiService.get<Map<String, dynamic>>(
      '${AppConfig.baseUrl}/Doctors/my-booking-settings',
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : Map<String, dynamic>.from(json as Map),
    );
  }

  // Update current doctor's booking settings
  Future<ApiResponse<Map<String, dynamic>>> updateMyBookingSettings(
      Map<String, dynamic> settings) async {
    return await _apiService.put<Map<String, dynamic>>(
      '${AppConfig.baseUrl}/Doctors/my-booking-settings',
      data: settings,
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : Map<String, dynamic>.from(json as Map),
    );
  }

  // Get specific appointment details
  Future<ApiResponse<Appointment>> getAppointmentDetails(String id) async {
    return await _apiService.get<Appointment>(
      '${AppConfig.baseUrl}/Appointments/$id',
      fromJson: (json) => Appointment.fromJson(json),
    );
  }

  // Update appointment status (e.g., Confirmed, Cancelled, Completed)
  Future<ApiResponse<Object>> updateAppointmentStatus(
      String appointmentId, String status,
      [String? reason]) async {
    final Map<String, dynamic> data = {'status': status};
    if (reason != null && reason.isNotEmpty) {
      data['cancellationReason'] = reason;
    }
    return await _apiService.put<Object>(
      '${AppConfig.baseUrl}/Appointments/$appointmentId/status',
      data: data,
    );
  }

  // Get current doctor profile
  Future<ApiResponse<Map<String, dynamic>>> getMyProfile() async {
    return await _apiService.get<Map<String, dynamic>>(
      '${AppConfig.baseUrl}/Doctors/profile',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // Update doctor profile
  Future<ApiResponse<Map<String, dynamic>>> updateProfile(
      Map<String, dynamic> data) async {
    return await _apiService.put<Map<String, dynamic>>(
      '${AppConfig.baseUrl}/Doctors/profile',
      data: data,
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // Add prescription to appointment
  Future<ApiResponse<Map<String, dynamic>>> addPrescription(
      String appointmentId, String prescription) async {
    return await _apiService.put<Map<String, dynamic>>(
      '${AppConfig.baseUrl}/Appointments/$appointmentId/prescription',
      data: {'prescription': prescription},
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // Create a structured prescription with medicines list → POST /api/Prescriptions
  Future<ApiResponse<Map<String, dynamic>>> createStructuredPrescription({
    required int appointmentId,
    required String diagnosis,
    String? notes,
    required List<Map<String, String>> medicines,
  }) async {
    final payload = {
      'appointmentId': appointmentId,
      'diagnosis': diagnosis,
      'notes': notes ?? '',
      'medicines': medicines
          .map((m) => {
                'medicineName': m['name'] ?? '',
                'dosage': m['dosage'] ?? '',
                'frequency': m['frequency'] ?? '',
                'duration': m['duration'] ?? '',
                'instructions': m['instructions'] ?? '',
              })
          .toList(),
    };
    return await _apiService.post<Map<String, dynamic>>(
      '${AppConfig.baseUrl}/Prescriptions',
      data: payload,
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : Map<String, dynamic>.from(json as Map),
    );
  }

  // Get a specific patient's medical history for doctor view
  Future<ApiResponse<List<MedicalHistory>>> getPatientMedicalHistory(
      int patientId) async {
    return await _apiService.get<List<MedicalHistory>>(
      '${AppConfig.baseUrl}/MedicalHistory/patient/$patientId',
      fromJson: (json) {
        if (json is List) {
          return json
              .map((item) => MedicalHistory.fromJson(
                  item is Map<String, dynamic>
                      ? item
                      : Map<String, dynamic>.from(item as Map)))
              .toList();
        }
        return [];
      },
    );
  }

  // Get a specific patient's emergency contacts for doctor view
  Future<ApiResponse<List<Map<String, dynamic>>>> getPatientEmergencyContacts(
      int patientId) async {
    return await _apiService.get<List<Map<String, dynamic>>>(
      '${AppConfig.baseUrl}/EmergencyContacts/user/$patientId',
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
  }

  Future<ApiResponse<List<Map<String, dynamic>>>>
      getUnreadNotifications() async {
    return await _apiService.get<List<Map<String, dynamic>>>(
      '${AppConfig.baseUrl}/Notifications/unread',
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
  }

  Future<ApiResponse<Object>> markNotificationRead(int id) async {
    return await _apiService.patch<Object>(
      '${AppConfig.baseUrl}/Notifications/$id/read',
      data: const {},
    );
  }

  // Get doctor's leaves
  Future<ApiResponse<List<Map<String, dynamic>>>> getMyLeaves() async {
    return await _apiService.get<List<Map<String, dynamic>>>(
      '${AppConfig.baseUrl}/Doctors/leaves',
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
  }

  // Add doctor's leave
  Future<ApiResponse<Object>> addLeave(Map<String, dynamic> data) async {
    return await _apiService.post<Object>(
      '${AppConfig.baseUrl}/Doctors/leaves',
      data: data,
    );
  }

  // Update doctor's leave
  Future<ApiResponse<Object>> updateLeave(
      int id, Map<String, dynamic> data) async {
    return await _apiService.put<Object>(
      '${AppConfig.baseUrl}/Doctors/leaves/$id',
      data: data,
    );
  }

  // Delete doctor's leave
  Future<ApiResponse<Object>> deleteLeave(int id) async {
    return await _apiService.delete<Object>(
      '${AppConfig.baseUrl}/Doctors/leaves/$id',
    );
  }
}
