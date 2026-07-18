import 'package:get/get.dart';
import '../../../data/models/user.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';
import '../../../routes/app_routes.dart';

class AdminDashboardController extends GetxController {
  final _authService = Get.find<AuthService>();
  final _apiService = Get.find<ApiService>();

  final Rx<User?> currentUser = Rx<User?>(null);
  final RxBool isLoading = false.obs;

  // Statistics
  final RxInt totalUsers = 0.obs;
  final RxInt totalStudents = 0.obs;
  final RxInt totalFaculty = 0.obs;
  final RxInt totalDoctors = 0.obs;
  final RxInt totalAppointments = 0.obs;
  final RxInt todayAppointments = 0.obs;
  final RxInt pendingVerifications = 0.obs;
  final RxInt systemAlerts = 0.obs;

  final RxList<Map<String, dynamic>> monthlyTrends =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> monthlyUserTrends =
      <Map<String, dynamic>>[].obs;

  // Recent activities
  final RxList<Map<String, dynamic>> recentActivities =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> notifications =
      <Map<String, dynamic>>[].obs;
  final RxList<User> recentUsers = <User>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    isLoading.value = true;
    try {
      currentUser.value = await _authService.getCurrentUser();
      await Future.wait([
        loadStatistics(),
        loadRecentActivities(),
        loadRecentUsers(),
        loadNotifications(),
      ]);
    } catch (e) {
      print('Error loading dashboard: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadStatistics() async {
    try {
      final response = await _apiService.get('/Admin/dashboard-stats');
      if (response.success && response.data != null) {
        final data = _asMap(response.data);
        totalUsers.value = _asInt(data['totalUsers'] ?? data['TotalUsers']);
        totalStudents.value =
            _asInt(data['totalStudents'] ?? data['TotalStudents']);
        totalFaculty.value =
            _asInt(data['totalFaculty'] ?? data['TotalFaculty']);
        totalDoctors.value =
            _asInt(data['totalDoctors'] ?? data['TotalDoctors']);
        totalAppointments.value =
            _asInt(data['totalAppointments'] ?? data['TotalAppointments']);
        todayAppointments.value =
            _asInt(data['todayAppointments'] ?? data['TodayAppointments']);
        pendingVerifications.value = _asInt(
            data['pendingVerifications'] ?? data['PendingVerifications']);
        systemAlerts.value =
            _asInt(data['systemAlerts'] ?? data['SystemAlerts']);

        if (data['monthlyTrends'] != null && data['monthlyTrends'] is List) {
          monthlyTrends.value =
              List<Map<String, dynamic>>.from(data['monthlyTrends']);
        }
        if (data['monthlyUserTrends'] != null &&
            data['monthlyUserTrends'] is List) {
          monthlyUserTrends.value =
              List<Map<String, dynamic>>.from(data['monthlyUserTrends']);
        }
      }
    } catch (e) {
      print('Error loading statistics: $e');
      totalUsers.value = 0;
      totalStudents.value = 0;
      totalFaculty.value = 0;
      totalDoctors.value = 0;
      totalAppointments.value = 0;
      todayAppointments.value = 0;
      pendingVerifications.value = 0;
      systemAlerts.value = 0;
    }
  }

  Future<void> loadRecentActivities() async {
    try {
      final response = await _apiService.get('/Admin/recent-activities');
      if (response.success && response.data != null) {
        recentActivities.value = _asMapList(response.data);
      }
    } catch (e) {
      print('Error loading activities: $e');
      recentActivities.clear();
    }
  }

  Future<void> loadRecentUsers() async {
    try {
      final response = await _apiService.get('/Admin/recent-users');
      if (response.success && response.data != null) {
        final users = _asList(response.data)
            .map((json) => User.fromJson(_asMap(json)))
            .toList();
        recentUsers.value = users;
      }
    } catch (e) {
      print('Error loading recent users: $e');
      recentUsers.clear();
    }
  }

  Future<void> loadNotifications() async {
    try {
      final response = await _apiService.get('/Admin/notifications');
      if (response.success && response.data != null) {
        notifications.value = _asMapList(response.data);
      }
    } catch (e) {
      print('Error loading notifications: $e');
      notifications.clear();
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    return <dynamic>[];
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    return _asList(value).map((item) => _asMap(item)).toList();
  }

  int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Future<void> refresh() async {
    await loadDashboardData();
  }

  // Navigation methods
  void manageUsers([String? role]) {
    Get.toNamed(AppRoutes.manageUsers,
        arguments: role != null ? {'role': role} : null);
  }

  void manageDoctors() {
    Get.toNamed(AppRoutes.manageDoctors);
  }

  void viewReports() {
    Get.toNamed(AppRoutes.reports);
  }

  void manageFeedback() {
    Get.toNamed(AppRoutes.manageFeedback);
  }

  void systemSettings() {
    Get.toNamed(AppRoutes.systemSettings);
  }

  void viewAllAppointments() {
    Get.toNamed(AppRoutes.adminAppointments);
  }

  void viewProfile() {
    Get.toNamed(AppRoutes.profile);
  }

  void viewSettings() {
    Get.toNamed(AppRoutes.settings);
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
