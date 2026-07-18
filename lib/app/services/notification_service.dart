import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:async';
import 'storage_service.dart';
import 'medicine_reminder_service.dart';
import 'api_service.dart';
import 'auth_service.dart';
import '../../config/app_config.dart';
import 'appointment_event_service.dart';

class NotificationService extends GetxService {
  final _logger = Logger();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  late final StorageService _storageService;
  Timer? _pollingTimer;
  final Set<int> _notifiedIds = {};

  Future<NotificationService> init() async {
    _logger.i('NotificationService: Initializing...');
    _storageService = Get.find<StorageService>();

    tz_data.initializeTimeZones();
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (e) {
      _logger.w('Failed to get local timezone, defaulting to UTC: $e');
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        _logger.i('Notification clicked: ${details.payload}');
      },
    );

    // Request permissions
    await _requestPermissions();

    // Start background polling for general notifications
    _startNotificationPolling();

    return this;
  }

  void _startNotificationPolling() {
    // Poll every 30 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _checkUnreadNotifications();
    });
  }

  Future<void> _checkUnreadNotifications() async {
    if (_isMuted()) return;

    try {
      final authService = Get.find<AuthService>();
      if (!authService.isAuthenticated.value) return;

      final apiService = Get.find<ApiService>();
      final response = await apiService.get<dynamic>(
        '${AppConfig.baseUrl}/Notifications/unread',
        fromJson: (json) => json,
      );

      if (response.success && response.data is List) {
        final notifications = (response.data as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        for (var notif in notifications) {
          final id =
              int.tryParse((notif['id'] ?? notif['Id'] ?? '').toString());
          if (id != null && !_notifiedIds.contains(id)) {
            _notifiedIds.add(id);

            final title =
                (notif['title'] ?? notif['Title'] ?? 'Notification').toString();
            final message =
                (notif['message'] ?? notif['Message'] ?? '').toString();
            final typeStr =
                (notif['type'] ?? notif['Type'] ?? '').toString();

            // Emit appointment event for real-time dashboard updates
            if (typeStr.toLowerCase().contains('appointment') || 
                title.toLowerCase().contains('appointment')) {
              try {
                Get.find<AppointmentEventService>()
                    .emit(AppointmentEvent(id.toString(), 'refresh'));
              } catch (_) {}
            }

            await showNotification(
              id: id,
              title: title,
              body: message,
              payload: id.toString(),
            );
          }
        }
      }
    } catch (e) {
      _logger.w('Error polling notifications: $e');
    }
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    super.onClose();
  }

  Future<void> _requestPermissions() async {
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();
    await _requestExactAlarmPermissionIfNeeded(androidImplementation);
  }

  Future<void> _requestExactAlarmPermissionIfNeeded(
    AndroidFlutterLocalNotificationsPlugin? androidImplementation,
  ) async {
    if (androidImplementation == null) {
      return;
    }

    try {
      await androidImplementation.requestExactAlarmsPermission();
    } catch (e) {
      _logger.w('Exact alarm permission request skipped: $e');
    }
  }

  bool _isMuted() => _storageService.isNotificationsMuted;

  // Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (_isMuted()) {
      _logger.i('Notifications muted. Skipping immediate notification $id');
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'medi_ai_channel',
      'Medi-AI Notifications',
      channelDescription: 'Main channel for Medi-AI notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  // Schedule notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    TimeOfDay? scheduledTime,
    DateTime? scheduledDateTime,
    String? payload,
  }) async {
    if (_isMuted()) {
      _logger.i('Notifications muted. Skipping scheduled notification $id');
      return;
    }

    final targetDateTime = scheduledDateTime ??
        DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          scheduledTime!.hour,
          scheduledTime.minute,
        );

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime.from(targetDateTime.toLocal(), tz.local);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'medi_ai_reminders_v2',
        'Medicine Reminders',
        channelDescription: 'Notifications for medicine reminders',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        vibrationPattern: Int64List.fromList(
            [0, 1000, 500, 1000, 500, 1000, 500, 1000, 500, 1000]),
      ),
    );

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    } on Exception catch (e) {
      final errorText = e.toString().toLowerCase();
      if (errorText.contains('exact_alarms_not_permitted') ||
          errorText.contains('exact alarms not permitted')) {
        _logger.w(
            'Exact alarms not permitted. Requesting permission and retrying.');
        final androidImplementation = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await _requestExactAlarmPermissionIfNeeded(androidImplementation);
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.alarmClock,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: payload,
        );
      } else {
        rethrow;
      }
    }

    _logger.i('Scheduled notification $id for $scheduledDate');
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
    _logger.i('Cancelled notification $id');
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Reschedules all saved medicine reminders from SharedPreferences
  /// This is called on app startup and after device boot
  Future<void> rescheduleSavedReminders() async {
    _logger.i('Rescheduling saved medicine reminders...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      // Find all dynamically generated keys for offline reminders
      for (final key in keys) {
        if (key.startsWith('offline_medicine_reminders_')) {
          await _rescheduleRemindersFromStorage(prefs, key, false);
        } else if (key.startsWith('offline_faculty_medicine_reminders_')) {
          await _rescheduleRemindersFromStorage(prefs, key, true);
        }
      }

      // Also trigger sync
      try {
        Get.find<MedicineReminderService>().syncPendingReminders();
      } catch (e) {
        // Ignored if service not initialized yet
      }

      _logger.i('Successfully rescheduled all saved reminders');
    } catch (e) {
      _logger.e('Error rescheduling saved reminders: $e');
    }
  }

  /// Helper method to reschedule reminders from a specific SharedPreferences key
  Future<void> _rescheduleRemindersFromStorage(
    SharedPreferences prefs,
    String key,
    bool isFacultyReminder,
  ) async {
    try {
      final String? remindersJson = prefs.getString(key);
      if (remindersJson == null || remindersJson.isEmpty) {
        _logger.i('No saved reminders found for key: $key');
        return;
      }

      final List<dynamic> decoded = jsonDecode(remindersJson);
      _logger
          .i('Found ${decoded.length} reminders to reschedule for key: $key');

      for (final reminderMap in decoded) {
        try {
          final reminder = Map<String, dynamic>.from(reminderMap as Map);
          await _rescheduleReminder(reminder, isFacultyReminder);
        } catch (e) {
          _logger.w('Error rescheduling individual reminder: $e');
        }
      }
    } catch (e) {
      _logger.e('Error loading reminders from storage key $key: $e');
    }
  }

  /// Reschedules a single reminder
  Future<void> _rescheduleReminder(
    Map<String, dynamic> reminder,
    bool isFacultyReminder,
  ) async {
    try {
      final reminderId = reminder['id']?.toString() ?? '';
      final medicineName = reminder['medicineName']?.toString() ?? 'Medicine';
      final dosage = reminder['dosage']?.toString() ?? '';
      final isActive = reminder['isActive'] == true;

      if (reminderId.isEmpty || !isActive) {
        return;
      }

      // Parse times
      List<String> timesApp = [];
      final timesRaw = reminder['times'];
      if (timesRaw is String) {
        if (timesRaw.trim().startsWith('[')) {
          try {
            final List<dynamic> parsed = jsonDecode(timesRaw);
            timesApp = parsed.map((e) => e.toString()).toList();
          } catch (_) {
            timesApp = timesRaw.replaceAll(RegExp(r'[\[\]"]'), '').split(',');
          }
        } else {
          timesApp = timesRaw.split(',');
        }
      } else if (timesRaw is List) {
        timesApp = timesRaw.map((e) => e.toString()).toList();
      }

      if (timesApp.isEmpty) {
        return;
      }

      // Schedule each time
      for (int i = 0; i < timesApp.length; i++) {
        try {
          final timeStr =
              timesApp[i].replaceAll(RegExp(r'[\[\]"\\/]'), '').trim();
          final format = DateFormat('hh:mm a');
          final dt = format.parse(timeStr);
          final timeOfDay = TimeOfDay(hour: dt.hour, minute: dt.minute);

          // Generate ID based on reminder type
          int notificationId;
          if (isFacultyReminder) {
            notificationId = ((reminderId.hashCode + i) & 0x7FFFFFFF) + 10000;
          } else {
            notificationId = (reminderId.hashCode + i) & 0x7FFFFFFF;
          }

          // Schedule the notification
          await scheduleNotification(
            id: notificationId,
            title: isFacultyReminder
                ? 'Work/Medicine Reminder'
                : 'Medicine Reminder',
            body: 'It\'s time to take $medicineName ($dosage)',
            scheduledTime: timeOfDay,
            payload: reminderId,
          );

          _logger.i(
            'Rescheduled notification $notificationId for $medicineName at $timeStr',
          );
        } catch (e) {
          _logger.w('Error scheduling individual time for reminder: $e');
        }
      }
    } catch (e) {
      _logger.e('Error rescheduling reminder: $e');
    }
  }
}
