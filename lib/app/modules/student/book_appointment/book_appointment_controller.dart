import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';
import 'package:medi_ai/config/app_config.dart';
import '../dashboard/student_dashboard_controller.dart';

class BookAppointmentController extends GetxController {
  final _authService = Get.find<AuthService>();
  final _apiService = Get.find<ApiService>();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Observables
  final RxList<Map<String, dynamic>> doctors = <Map<String, dynamic>>[].obs;
  final RxList<String> specializations = <String>[].obs;
  final RxList<Map<String, dynamic>> availableSlots =
      <Map<String, dynamic>>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingSlots = false.obs;

  // Form Values
  final Rx<String?> selectedSpecialization = Rx<String?>(null);
  final Rx<String?> selectedDoctorId = Rx<String?>(null);
  final Rx<DateTime?> selectedDate = Rx<DateTime?>(null);
  // final Rx<TimeOfDay?> selectedTime = Rx<TimeOfDay?>(null);
  final Rx<Map<String, dynamic>?> selectedSlot =
      Rx<Map<String, dynamic>?>(null);

  final symptomsController = TextEditingController();
  final notesController = TextEditingController();

  Map<String, dynamic>? get selectedDoctor {
    if (selectedDoctorId.value == null) return null;
    return doctors
        .firstWhereOrNull((d) => d['id'].toString() == selectedDoctorId.value);
  }

  List<Map<String, dynamic>> get filteredDoctors {
    if (selectedSpecialization.value == null) return doctors;
    return doctors
        .where((d) => d['specialization'] == selectedSpecialization.value)
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadDoctors();
  }

  Future<void> loadDoctors() async {
    isLoading.value = true;
    try {
      final response =
          await _apiService.get('${AppConfig.baseUrl}/doctors/available');
      if (response.success && response.data != null) {
        final List<dynamic> data = response.data;
        doctors.value =
            data.map((item) => item as Map<String, dynamic>).toList();

        final specs = doctors
            .map((d) => d['specialization'] as String?)
            .where((s) => s != null && s.isNotEmpty)
            .toSet()
            .toList();
        specializations.value = specs.cast<String>();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load doctors');
    } finally {
      isLoading.value = false;
    }
  }

  void onSpecializationChanged(String? value) {
    selectedSpecialization.value = value;
    selectedDoctorId.value = null;
    selectedSlot.value = null;
    availableSlots.clear();
  }

  void onDoctorChanged(String? doctorId) {
    selectedDoctorId.value = doctorId;
    selectedSlot.value = null;
    availableSlots.clear();

    if (doctorId != null && selectedDate.value != null) {
      fetchAvailableSlots();
    }
  }

  void onDateSelected(DateTime date) {
    selectedDate.value = date;
    selectedSlot.value = null;

    if (selectedDoctorId.value != null) {
      fetchAvailableSlots();
    }
  }

  Future<void> fetchAvailableSlots() async {
    if (selectedDoctorId.value == null || selectedDate.value == null) return;

    isLoadingSlots.value = true;
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value!);
      final response = await _apiService.get(
          '/appointments/available-slots',
          queryParameters: {
            'doctorId': selectedDoctorId.value,
            'date': dateStr
          });

      if (response.success && response.data != null) {
        final List<dynamic> slotsList = response.data;
        availableSlots.value =
            slotsList.map((s) => {'time': s.toString()}).toList();
      } else {
        availableSlots.clear();
        if (response.message != "Doctor is not available on this day") {
          if (response.message?.toLowerCase().contains('leave') == true) {
            Get.defaultDialog(
              title: 'Doctor Unavailable',
              middleText:
                  'The selected doctor is on leave during this date. Please select another date.',
              textConfirm: 'Okay',
              confirmTextColor: Colors.white,
              buttonColor: const Color(0xFF2563EB), // AppTheme.primary
              onConfirm: () {
                Get.back();
              },
            );
          } else {
            Get.snackbar('Notice', response.message);
          }
        }
      }
    } catch (e) {
      print('Error fetching slots: $e');
      availableSlots.clear();
    } finally {
      isLoadingSlots.value = false;
    }
  }

  Future<void> bookAppointment() async {
    if (!formKey.currentState!.validate()) return;

    if (selectedDoctorId.value == null) {
      Get.snackbar('Error', 'Please select a doctor');
      return;
    }
    if (selectedDate.value == null) {
      Get.snackbar('Error', 'Please select a date');
      return;
    }
    if (selectedSlot.value == null) {
      Get.snackbar('Error', 'Please select a time slot');
      return;
    }

    isLoading.value = true;
    try {
      final currentUser = await _authService.getCurrentUser();

      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value!);
      final timeStr = selectedSlot.value!['time']; // HH:mm
      final dateTimeStr = '${dateStr}T$timeStr:00'; // ISO format

      final appointmentData = {
        'patientId': currentUser?.id.toString(),
        'doctorId': selectedDoctorId.value,
        'dateTime': dateTimeStr,
        'symptoms': symptomsController.text,
        'notes': notesController.text,
        'status': 'Pending'
      };

      final response =
          await _apiService.post('/appointments', data: appointmentData);

      if (response.success) {
        // Refresh dashboards so the new appointment shows immediately
        if (Get.isRegistered<StudentDashboardController>()) {
          await Get.find<StudentDashboardController>().refresh();
        }

        Get.back();
        Get.snackbar('Success', 'Appointment booked successfully',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM);
      } else {
        final lowerMsg = response.message?.toLowerCase() ?? '';
        if (lowerMsg.contains('already booked') || lowerMsg.contains('taken') || lowerMsg.contains('maximum appointments')) {
          // It's a race condition or slot became unavailable
          selectedSlot.value = null;
          await fetchAvailableSlots();
          Get.snackbar(
            'Slot Unavailable',
            'This slot was just taken or max capacity reached. Please pick another slot.',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        } else {
          Get.snackbar(
            'Booking Failed',
            response.message,
            backgroundColor: Colors.red.withOpacity(0.1),
            colorText: Colors.red,
            duration: const Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
      // Save locally for offline sync
      try {
        final prefs = await SharedPreferences.getInstance();
        final offlineKey = 'offline_appointments';
        final String? existingJson = prefs.getString(offlineKey);
        List<dynamic> offlineList = [];
        if (existingJson != null) {
          offlineList = jsonDecode(existingJson);
        }

        final currentUser = await _authService.getCurrentUser();
        final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value!);
        final timeStr = selectedSlot.value!['time'];
        final dateTimeStr = '${dateStr}T$timeStr:00';

        offlineList.add({
          'patientId': currentUser?.id.toString(),
          'doctorId': selectedDoctorId.value,
          'dateTime': dateTimeStr,
          'symptoms': symptomsController.text,
          'notes': notesController.text,
          'status': 'Pending',
          'offlineId': DateTime.now().millisecondsSinceEpoch.toString(),
        });

        await prefs.setString(offlineKey, jsonEncode(offlineList));

        Get.back();
        Get.snackbar(
            'Offline Mode', 'Appointment saved locally. Will sync when online.',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM);
      } catch (innerErr) {
        Get.snackbar(
            'Error', 'Failed to book appointment and failed to save offline');
      }
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    symptomsController.dispose();
    notesController.dispose();
    super.onClose();
  }
}
