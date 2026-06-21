import 'package:get/get.dart';
import '../../../data/models/appointment.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import 'package:medi_ai/config/app_config.dart';

class PrescriptionHistoryController extends GetxController {
  final _apiService = Get.find<ApiService>();
  final _authService = Get.find<AuthService>();

  final RxBool isLoading = false.obs;
  final RxList<Appointment> prescriptionAppointments = <Appointment>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadPrescriptions();
  }

  Future<void> loadPrescriptions() async {
    isLoading.value = true;
    try {
      final user = await _authService.getCurrentUser();
      if (user == null || user.id.isEmpty) {
        return;
      }

      final response = await _apiService.get(
        '${AppConfig.baseUrl}/Prescriptions/my-prescriptions',
      );

      if (response.success && response.data is List) {
        final list = response.data as List;
        prescriptionAppointments.value = list.map((item) {
          final json = item as Map<String, dynamic>;
          
          // Build a detailed prescription string from Diagnosis, Notes and Medicines
          String fullPrescription = 'Diagnosis: ${json["diagnosis"] ?? json["Diagnosis"] ?? "N/A"}\n';
          final notes = json["notes"] ?? json["Notes"];
          if (notes != null && notes.toString().isNotEmpty) {
            fullPrescription += 'Notes: $notes\n';
          }
          
          fullPrescription += '\nMedicines:\n';
          final medicines = json["medicines"] ?? json["Medicines"];
          if (medicines != null && medicines is List && medicines.isNotEmpty) {
            for (var med in medicines) {
              final medName = med["medicineName"] ?? med["MedicineName"] ?? "Unknown";
              final dosage = med["dosage"] ?? med["Dosage"] ?? "";
              final frequency = med["frequency"] ?? med["Frequency"] ?? "";
              fullPrescription += '• $medName $dosage - $frequency\n';
              
              final instructions = med["instructions"] ?? med["Instructions"];
              if (instructions != null && instructions.toString().isNotEmpty) {
                fullPrescription += '  Instructions: $instructions\n';
              }
            }
          } else {
            fullPrescription += 'No medicines prescribed.\n';
          }

          return Appointment(
            id: json["appointmentId"]?.toString() ?? json["AppointmentId"]?.toString() ?? '',
            patientId: user.id,
            patientName: user.name,
            doctorId: '',
            doctorName: json["doctorName"]?.toString() ?? json["DoctorName"]?.toString() ?? 'Unknown',
            specialization: 'Doctor Consultation',
            dateTime: DateTime.tryParse(json["appointmentDate"]?.toString() ?? json["AppointmentDate"]?.toString() ?? '') ?? DateTime.now(),
            status: 'Completed',
            prescription: fullPrescription.trim(),
            createdAt: DateTime.tryParse(json["createdAt"]?.toString() ?? json["CreatedAt"]?.toString() ?? '') ?? DateTime.now(),
          );
        }).toList();
      } else {
        prescriptionAppointments.clear();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load prescriptions');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshData() async {
    await loadPrescriptions();
  }
}
