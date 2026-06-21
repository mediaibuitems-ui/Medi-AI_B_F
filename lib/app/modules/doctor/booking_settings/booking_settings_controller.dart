import 'package:get/get.dart';
import '../../../services/auth_service.dart';
import '../../../services/doctor_service.dart';
import '../../../data/models/user.dart';

class BookingSettingsController extends GetxController {
  final _authService = Get.find<AuthService>();
  final _doctorService = Get.find<DoctorService>();

  final Rx<User?> currentUser = Rx<User?>(null);
  
  // Appointment settings
  final RxInt appointmentDuration = 30.obs; // in minutes
  final RxInt maxPatientsPerDay = 16.obs;
  final RxBool autoConfirmAppointments = false.obs;
  final RxBool enableBreakTime = false.obs;
  final RxString breakStartTime = '12:00'.obs;
  final RxString breakEndTime = '13:00'.obs;
  
  // Reminder settings
  final RxBool enableAppointmentReminders = true.obs;
  final RxInt reminderNotificationMinutes = 15.obs;
  
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  Future<void> loadSettings() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      currentUser.value = await _authService.getCurrentUser();

      final response = await _doctorService.getMyBookingSettings();
      if (response.success && response.data != null) {
        _applySettings(response.data!);
      } else {
        errorMessage.value = response.message;
      }
    } catch (e) {
      errorMessage.value = 'Error loading settings: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void _applySettings(Map<String, dynamic> data) {
    int readInt(String key, int fallback) {
      final value = data[key] ?? data[_toPascalCase(key)];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    bool readBool(String key, bool fallback) {
      final value = data[key] ?? data[_toPascalCase(key)];
      if (value is bool) return value;
      final text = value?.toString().toLowerCase();
      if (text == 'true') return true;
      if (text == 'false') return false;
      return fallback;
    }

    String readString(String key, String fallback) {
      final value = data[key] ?? data[_toPascalCase(key)];
      final parsed = value?.toString().trim() ?? '';
      return parsed.isEmpty ? fallback : parsed;
    }

    appointmentDuration.value = readInt('appointmentDuration', 30);
    maxPatientsPerDay.value = readInt('maxPatientsPerDay', 16);
    autoConfirmAppointments.value = readBool('autoConfirmAppointments', false);
    enableBreakTime.value = readBool('enableBreakTime', false);
    breakStartTime.value = readString('breakStartTime', '12:00');
    breakEndTime.value = readString('breakEndTime', '13:00');
    enableAppointmentReminders.value = readBool('enableAppointmentReminders', true);
    reminderNotificationMinutes.value = readInt('reminderNotificationMinutes', 15);
  }

  Future<void> saveSettings() async {
    isSaving.value = true;
    errorMessage.value = '';
    try {
      final payload = {
        'appointmentDuration': appointmentDuration.value,
        'maxPatientsPerDay': maxPatientsPerDay.value,
        'autoConfirmAppointments': autoConfirmAppointments.value,
        'enableBreakTime': enableBreakTime.value,
        'breakStartTime': breakStartTime.value,
        'breakEndTime': breakEndTime.value,
        'enableAppointmentReminders': enableAppointmentReminders.value,
        'reminderNotificationMinutes': reminderNotificationMinutes.value,
      };

      final response = await _doctorService.updateMyBookingSettings(payload);
      if (response.success) {
        Get.snackbar('Success', 'Settings saved successfully');
      } else {
        errorMessage.value = response.message;
        Get.snackbar('Error', response.message);
      }
    } catch (e) {
      errorMessage.value = 'Error saving settings: $e';
      Get.snackbar('Error', 'Failed to save settings: $e');
    } finally {
      isSaving.value = false;
    }
  }

  void setAppointmentDuration(int minutes) {
    // Only allow valid durations: 15, 20, 30, 45, 60
    if ([15, 20, 30, 45, 60].contains(minutes)) {
      appointmentDuration.value = minutes;
    }
  }

  void setMaxPatientsPerDay(int max) {
    if (max > 0 && max <= 50) {
      maxPatientsPerDay.value = max;
    }
  }

  void setReminderMinutes(int minutes) {
    if (minutes >= 5 && minutes <= 120) {
      reminderNotificationMinutes.value = minutes;
    }
  }

  String _toPascalCase(String key) {
    if (key.isEmpty) return key;
    return key[0].toUpperCase() + key.substring(1);
  }
}
