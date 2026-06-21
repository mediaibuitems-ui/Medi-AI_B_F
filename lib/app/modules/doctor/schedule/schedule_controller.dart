import 'package:get/get.dart';
import '../../../services/doctor_service.dart';

class ScheduleController extends GetxController {
  final _doctorService = Get.find<DoctorService>();

  static const List<String> weekDays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final RxList<Map<String, dynamic>> schedule = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Show editable defaults immediately so doctor can set schedule without waiting for API.
    schedule.value = _buildDefaultSchedule();
    loadSchedule();
  }

  List<Map<String, dynamic>> _buildDefaultSchedule() {
    return weekDays
        .map(
          (day) => <String, dynamic>{
            'scheduleId': null,
            'dayOfWeek': day,
            'startTime': '09:00',
            'endTime': '17:00',
            'isAvailable': false,
          },
        )
        .toList();
  }

  Future<void> loadSchedule() async {
    isLoading.value = true;
    try {
      final response = await _doctorService.getMySchedule();
      if (response.success && response.data != null && response.data!.isNotEmpty) {
        final serverSchedule = response.data!
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

        schedule.value = weekDays.map((day) {
          final existing = serverSchedule.firstWhere(
            (item) => (item['dayOfWeek'] ?? item['DayOfWeek'] ?? '').toString().toLowerCase() == day.toLowerCase(),
            orElse: () => <String, dynamic>{
              'dayOfWeek': day,
              'startTime': '09:00',
              'endTime': '17:00',
              'isAvailable': false,
            },
          );

          return {
            'scheduleId': existing['scheduleId'] ?? existing['ScheduleId'],
            'dayOfWeek': existing['dayOfWeek'] ?? existing['DayOfWeek'] ?? day,
            'startTime': existing['startTime'] ?? existing['StartTime'] ?? '09:00',
            'endTime': existing['endTime'] ?? existing['EndTime'] ?? '17:00',
            'isAvailable': existing['isAvailable'] ?? existing['IsAvailable'] ?? false,
          };
        }).toList();
      } else {
        // Backend can return no rows for new doctors; keep local defaults editable.
        schedule.value = _buildDefaultSchedule();
      }
    } catch (e) {
      schedule.value = _buildDefaultSchedule();
      Get.snackbar('Error', 'Failed to load schedule');
    } finally {
      isLoading.value = false;
    }
  }

  void updateDayAvailability(int index, bool val) {
    final item = Map<String, dynamic>.from(schedule[index]);
    item['isAvailable'] = val;
    schedule[index] = item;
  }

  void updateDayTime(int index, {required bool isStart, required String value}) {
    final item = Map<String, dynamic>.from(schedule[index]);
    if (isStart) {
      item['startTime'] = value;
      item['StartTime'] = value;
    } else {
      item['endTime'] = value;
      item['EndTime'] = value;
    }
    schedule[index] = item;
  }

  Future<void> saveSchedule() async {
    isSaving.value = true;
    try {
      final payload = schedule
          .map((item) => {
                'dayOfWeek': item['dayOfWeek'] ?? item['DayOfWeek'],
                'startTime': item['startTime'] ?? item['StartTime'] ?? '09:00',
                'endTime': item['endTime'] ?? item['EndTime'] ?? '17:00',
                'isAvailable': item['isAvailable'] == true || item['IsAvailable'] == true,
              })
          .toList();

      final response = await _doctorService.updateSchedule(payload);
      if (response.success) {
        Get.snackbar('Success', 'Schedule updated successfully',
          backgroundColor: Get.theme.primaryColor, colorText: Get.theme.canvasColor);
      } else {
        Get.snackbar('error', response.message);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save schedule');
    } finally {
      isSaving.value = false;
    }
  }
}

