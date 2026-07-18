import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/user.dart';
import '../../../data/models/appointment.dart';
import '../../../services/auth_service.dart';
import '../../../services/doctor_service.dart';
import '../../../services/notification_service.dart';
import '../../../routes/app_routes.dart';
import '../../../services/appointment_event_service.dart';

class DoctorDashboardController extends GetxController {
  final _authService = Get.find<AuthService>();
  final _doctorService = Get.find<DoctorService>();
  final _notificationService = Get.find<NotificationService>();

  final Rx<User?> currentUser = Rx<User?>(null);
  final RxList<Appointment> _allTodayAppointments = <Appointment>[].obs;
  final RxList<Appointment> upcomingAppointments = <Appointment>[].obs;
  final RxString activeFilter = ''.obs; // '' means all, 'completed', 'pending'

  List<Appointment> get todayAppointments {
    if (activeFilter.value.isEmpty) {
      return _allTodayAppointments;
    }
    if (activeFilter.value == 'completed') {
      return _allTodayAppointments.where((apt) {
        final s = apt.status.toLowerCase();
        return s == 'completed' || s == 'checked';
      }).toList();
    }
    if (activeFilter.value == 'pending') {
      return _allTodayAppointments.where((apt) {
        final s = apt.status.toLowerCase();
        return s == 'pending' || s == 'scheduled' || s == 'confirmed';
      }).toList();
    }
    return _allTodayAppointments;
  }

  final RxBool isLoading = false.obs;
  final RxList<Map<String, dynamic>> unreadNotifications =
      <Map<String, dynamic>>[].obs;
  // Statistics
  final RxInt totalPatientsToday = 0.obs;
  final RxInt completedToday = 0.obs;
  final RxInt pendingToday = 0.obs;
  final RxInt totalPatients = 0.obs;

  StreamSubscription? _eventSubscription;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();

    // Listen for appointment events and refresh immediately when they occur
    final eventService = Get.isRegistered<AppointmentEventService>()
        ? Get.find<AppointmentEventService>()
        : Get.put(AppointmentEventService());
    _eventSubscription = eventService.stream.listen((event) async {
      try {
        // If an appointment changed, refresh lists so cancelled/updated items disappear
        await loadUpcomingAppointments();
        await loadTodayAppointments();
      } catch (_) {}
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
      currentUser.value = await _authService.getCurrentUser();
      await Future.wait([
        loadTodayAppointments(),
        loadUpcomingAppointments(),
        loadStatistics(),
        loadUnreadNotifications(),
      ]);
    } catch (e) {
      print('Error loading dashboard: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadTodayAppointments() async {
    try {
      final response = await _doctorService.getTodayAppointments();
      if (response.success && response.data != null) {
        _allTodayAppointments.value = response.data!;

        // Calculate today's statistics
        totalPatientsToday.value = _allTodayAppointments.length;
        // Match backend status values: Pending, Scheduled, Completed, Checked
        completedToday.value = _allTodayAppointments.where((apt) {
          final s = apt.status.toLowerCase();
          return s == 'completed' || s == 'checked';
        }).length;
        pendingToday.value = _allTodayAppointments.where((apt) {
          final s = apt.status.toLowerCase();
          return s == 'pending' || s == 'scheduled' || s == 'confirmed';
        }).length;
      }
    } catch (e) {
      print('Error loading today appointments: $e');
    }
  }

  Future<void> loadUpcomingAppointments() async {
    try {
      final response = await _doctorService.getUpcomingAppointments();
      if (response.success && response.data != null) {
        upcomingAppointments.value = response.data!;
      }
    } catch (e) {
      print('Error loading upcoming appointments: $e');
    }
  }

  Future<void> loadStatistics() async {
    try {
      final response = await _doctorService.getStatistics();
      if (response.success && response.data != null) {
        final data = response.data!;

        if (data['totalPatients'] != null) {
          totalPatients.value = data['totalPatients'];
        }

        if (data['todayTotal'] != null) {
          totalPatientsToday.value = data['todayTotal'];
        }
        if (data['completedToday'] != null) {
          completedToday.value = data['completedToday'];
        }
        if (data['pendingToday'] != null) {
          pendingToday.value = data['pendingToday'];
        }
      }
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  Future<void> loadUnreadNotifications() async {
    try {
      final response = await _doctorService.getUnreadNotifications();
      if (response.success && response.data != null) {
        unreadNotifications.value = response.data!;
      }
    } catch (e) {
      print('Error loading unread notifications: $e');
    }
  }

  @override
  Future<void> refresh() async {
    await loadDashboardData();
  }

  void viewAppointment(Appointment appointment) {
    Get.toNamed(
      AppRoutes.appointmentDetail,
      arguments: {'appointment': appointment},
    );
  }

  void viewAllAppointments() {
    Get.toNamed(AppRoutes.myAppointments);
  }

  void viewPatients() {
    Get.toNamed(AppRoutes.patients);
  }

  void viewSchedule() {
    Get.toNamed(AppRoutes.schedule);
  }

  void viewProfile() {
    Get.toNamed(AppRoutes.doctorProfile);
  }

  void viewBookingSettings() {
    Get.toNamed(AppRoutes.bookingSettings);
  }

  void viewSettings() {
    Get.toNamed(AppRoutes.doctorSettings);
  }

  void viewNotifications() {
    Get.toNamed(AppRoutes.notifications);
  }

  void viewFeedback() {
    Get.toNamed(AppRoutes.feedback);
  }

  void toggleFilter(String filter) {
    if (activeFilter.value == filter) {
      activeFilter.value = '';
    } else {
      activeFilter.value = filter;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    Get.offAllNamed(AppRoutes.login);
  }

  /// Update appointment status (Confirmed or Cancelled) from dashboard
  Future<void> updateAppointmentStatus(String appointmentId, String status,
      [String? reason]) async {
    isLoading.value = true;
    try {
      final response = await _doctorService.updateAppointmentStatus(
          appointmentId, status, reason);
      if (response.success) {
        Get.snackbar('Success', 'Appointment updated');
        await loadDashboardData();
      } else {
        Get.snackbar('Error', response.message);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update appointment status');
    }
  }

  Future<void> confirmAppointment(String appointmentId) async {
    await updateAppointmentStatus(appointmentId, 'Confirmed');
  }

  Future<void> declineAppointment(String appointmentId,
      [String? reason]) async {
    await updateAppointmentStatus(appointmentId, 'Cancelled', reason);
  }

  Future<void> deleteAppointment(String appointmentId) async {
    isLoading.value = true;
    try {
      final response = await Get.find<ApiService>().delete('/Appointments/$appointmentId');
      if (response.success) {
        Get.snackbar('Success', 'Appointment deleted permanently',
            backgroundColor: Colors.redAccent, colorText: Colors.white);
        await loadDashboardData();
      } else {
        Get.snackbar('Error', response.message);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete appointment');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsChecked(String appointmentId) async {
    await updateAppointmentStatus(appointmentId, 'Checked');
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
      case 'pending':
        return const Color(0xFFF59E0B); // Orange (Warning)
      case 'confirmed':
        return const Color(0xFF0891B2); // Cyan/Blue (Primary)
      case 'completed':
      case 'checked':
        return const Color(0xFF4CAF50); // Green
      case 'cancelled':
        return const Color(0xFFF44336); // Red
      case 'in_progress':
        return const Color(0xFFFF9800); // Orange
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  String getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return 'Scheduled';
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
      case 'checked':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'in_progress':
        return 'In progress';
      default:
        return status;
    }
  }
}
