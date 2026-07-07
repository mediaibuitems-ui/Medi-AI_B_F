import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/user.dart';
import '../../../data/models/appointment.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';
import '../../../routes/app_routes.dart';
import '../../../services/appointment_event_service.dart';
import 'dart:async';
import '../../../../config/app_config.dart';

class FacultyDashboardController extends GetxController {
  final _authService = Get.find<AuthService>();
  final _apiService = Get.find<ApiService>();

  final Rx<User?> currentUser = Rx<User?>(null);
  final RxList<Appointment> upcomingAppointments = <Appointment>[].obs;
  final RxList<Appointment> recentAppointments = <Appointment>[].obs;
  final RxBool isLoading = false.obs;

  // Statistics
  final RxInt totalAppointments = 0.obs;
  final RxInt completedAppointments = 0.obs;
  final RxInt upcomingCount = 0.obs;

  final RxInt unreadNotifications = 0.obs;

  StreamSubscription? _eventSubscription;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();

    // Listen for appointment events (created/updated/cancelled) to refresh UI
    final eventService = Get.isRegistered<AppointmentEventService>()
        ? Get.find<AppointmentEventService>()
        : Get.put(AppointmentEventService());
    _eventSubscription = eventService.stream.listen((event) {
      // For now refresh whole dashboard on any appointment change
      refresh();
    });
  }

  @override
  void onClose() {
    _eventSubscription?.cancel();
    super.onClose();
  }

  Future<void> loadDashboardData() async {
    isLoading.value = true;
    try {
      final user = await _authService.getCurrentUser();
      currentUser.value = user;

      // SAFETY CHECK: If the ID is missing, the cache is corrupted!
      if (user == null || user.id.isEmpty) {
        print('⛔ Error: User data corrupted. Forcing auto-logout.');
        await logout(); 
        return;
      }

      await Future.wait([
        loadAppointments(),
        loadRecentAppointments(),
        _loadUnreadNotifications(),
      ]);
    } catch (e) {
      print('Error loading dashboard: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final response = await _apiService.get('/Notifications/unread');
      if (response.success && response.data is List) {
        unreadNotifications.value = (response.data as List).length;
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  Future<void> loadAppointments() async {
    try {
      final response = await _apiService.get(
        '${AppConfig.baseUrl}/Appointments/student/${currentUser.value?.id}/upcoming',
      );
      if (response.success && response.data is List) {
        final list = response.data as List;
        upcomingAppointments.value =
            list.map((json) => Appointment.fromJson(json)).toList();
      } else {
        upcomingAppointments.clear();
      }

      _recomputeStatistics();
    } catch (e) {
      print('Error loading appointments: $e');
      upcomingAppointments.clear();
      _recomputeStatistics();
    }
  }

  Future<void> loadRecentAppointments() async {
    try {
      final response = await _apiService.get(
        '${AppConfig.baseUrl}/Appointments/student/${currentUser.value?.id}/history',
      );
      if (response.success && response.data != null) {
        final Map<String, dynamic> data = response.data as Map<String, dynamic>;
        final List<dynamic> list = data['items'] as List<dynamic>;

        final now = DateTime.now();
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        recentAppointments.value = list
            .map((json) => Appointment.fromJson(json))
            .where((a) => a.dateTime.isAfter(thirtyDaysAgo))
            .toList();
      } else {
        recentAppointments.clear();
      }

      _recomputeStatistics();
    } catch (e) {
      print('Error loading history: $e');
      recentAppointments.clear();
      _recomputeStatistics();
    }
  }

  void _recomputeStatistics() {
    upcomingCount.value = upcomingAppointments.length;

    final completed = recentAppointments
        .where((a) => a.status.toLowerCase() == 'completed')
        .length;
    completedAppointments.value = completed;

    totalAppointments.value =
        upcomingAppointments.length + recentAppointments.length;
  }

  Future<void> updateAppointment(String appointmentId, String doctorId,
      DateTime newDate, String newTime, String symptoms, String notes) async {
    isLoading.value = true;
    try {
      final dateTimeStr =
          '${DateFormat('yyyy-MM-dd').format(newDate)}T$newTime:00';

      final data = {
        'doctorId': doctorId,
        'dateTime': dateTimeStr,
        'symptoms': symptoms,
        'notes': notes
      };

      final response =
          await _apiService.put('/Appointments/$appointmentId', data: data);

      if (response.success) {
        await refresh(); // Reload lists
        if (Get.isDialogOpen ?? false) Get.back(); // Close dialog
        Get.snackbar('Success', 'Appointment updated successfully',
            backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar('Error', response.message);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update appointment');
    } finally {
      isLoading.value = false;
    }
  }

  bool canEditAppointment(Appointment appointment) {
    if (appointment.status != 'Pending') return false;

    final appointmentDateTime = appointment.dateTime;
    final now = DateTime.now();
    final difference = appointmentDateTime.difference(now).inMinutes;

    // Allow edit only if appointment is more than 30 minutes away
    return difference > 30;
  }

  Future<void> cancelAppointment(String appointmentId) async {
    isLoading.value = true;
    try {
      final response = await _apiService.delete('/Appointments/$appointmentId');
      if (response.success) {
        // Broadcast cancellation so doctor and other views update immediately
        final eventService = Get.isRegistered<AppointmentEventService>()
            ? Get.find<AppointmentEventService>()
            : Get.put(AppointmentEventService());
        eventService.emit(AppointmentEvent(appointmentId, 'cancelled'));

        await refresh();
        Get.snackbar('Success', 'Appointment cancelled',
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      } else {
        Get.snackbar('error', response.message);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to cancel appointment');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    await loadDashboardData();
  }

  void bookAppointment() {
    Get.toNamed(AppRoutes.bookAppointment);
  }

  void viewAppointments() {
    Get.toNamed(AppRoutes.myAppointments);
  }

  void goToPrescriptionHistory() {
    Get.toNamed(AppRoutes.prescriptionHistory);
  }

  void healthAnalyzer() {
    Get.toNamed(AppRoutes.symptomAnalyzerInput);
  }

  void medicineReminders() {
    Get.toNamed(AppRoutes.facultyMedicineReminders);
  }

  void viewMedicalHistory() {
    Get.toNamed(AppRoutes.medicalHistory);
  }

  void viewEmergencyContacts() {
    Get.toNamed(AppRoutes.emergencyContacts);
  }

  void viewProfile() {
    Get.toNamed(AppRoutes.profile);
  }

  void goToFeedback() {
    Get.toNamed(AppRoutes.feedback);
  }

  void goToSettings() {
    Get.toNamed(AppRoutes.settings);
  }

  void viewAppointment(Appointment appointment) {
    Get.toNamed(
      AppRoutes.appointmentDetail,
      arguments: {'appointment': appointment},
    );
  }

  Future<void> logout() async {
    await _authService.logout();
    Get.offAllNamed(AppRoutes.login);
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
