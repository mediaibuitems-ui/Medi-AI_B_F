import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'notification_service.dart';
import '../../config/app_config.dart';

class MedicineReminderService extends GetxService {
  final _apiService = Get.find<ApiService>();
  final _notificationService = Get.find<NotificationService>();

  Future<MedicineReminderService> init() async {
    return this;
  }

  Future<void> scheduleLocalReminder({
    required int id,
    required String title,
    required String body,
    required TimeOfDay scheduledTime,
    String? payload,
  }) async {
    await _notificationService.scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      payload: payload,
    );
  }

  Future<List<int>> syncReminders(List<Map<String, dynamic>> reminders) async {
    final mapped = reminders.map((r) {
      final timesRaw = (r['times'] ?? '').toString();
      final startDateRaw = (r['startDate'] ?? '').toString().trim();
      final endDateRaw = (r['endDate'] ?? '').toString().trim();
      final times = timesRaw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      var parsedId = int.tryParse((r['id'] ?? '').toString());
      // Prevent int32 overflow in C# backend (offline generated IDs are millisecondsSinceEpoch)
      if (parsedId != null && parsedId > 2147483647) {
        parsedId = null;
      } else if (parsedId != null && parsedId < 0) {
        parsedId = null; // Negative IDs are also temporary offline IDs
      }

      return {
        'id': parsedId,
        'medicineName': (r['medicineName'] ?? '').toString(),
        'dosage': (r['dosage'] ?? '').toString(),
        'frequency': (r['frequency'] ?? 'Custom').toString(),
        'customFrequency': r['customFrequency'],
        'times': times,
        'startDate': startDateRaw.isEmpty ? null : startDateRaw,
        'endDate': endDateRaw.isEmpty ? null : endDateRaw,
        'notes': (r['notes'] ?? '').toString(),
        'isActive': r['isActive'] == true,
      };
    }).toList();

    final response = await _apiService.post<dynamic>(
      '${AppConfig.baseUrl}/MedicineReminders/sync',
      data: {'reminders': mapped},
      requiresAuth: true,
    );

    if (!response.success) {
      throw Exception(response.message);
    }
    
    final data = response.data;
    if (data is Map && data['reminderIds'] != null) {
      final List<dynamic> ids = data['reminderIds'];
      return ids.map((e) => int.parse(e.toString())).toList();
    }
    return [];
  }

  Future<void> syncPendingReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) =>
          k.startsWith('offline_medicine_reminders_') ||
          k.startsWith('offline_faculty_medicine_reminders_'));

      for (final key in keys) {
        final String? remindersJson = prefs.getString(key);
        if (remindersJson == null || remindersJson.isEmpty) continue;

        final List<dynamic> decoded = jsonDecode(remindersJson);
        final List<Map<String, dynamic>> reminders =
            decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();

        // Find unsynced
        final unsynced = reminders.where((r) => r['isSynced'] != true).toList();
        if (unsynced.isNotEmpty) {
          try {
            final resultIds = await syncReminders(unsynced);
            // If successful, update local storage and reconcile IDs
            for (int i = 0; i < unsynced.length; i++) {
              unsynced[i]['isSynced'] = true;
              if (i < resultIds.length) {
                // If the old ID was temporary (negative or string-based timestamp), update it.
                // We keep the logic simple: always use the server's ID.
                unsynced[i]['id'] = resultIds[i].toString();
              }
            }
            await prefs.setString(key, jsonEncode(reminders));
          } catch (e) {
            // Fails silently if offline
          }
        }
      }
    } catch (e) {
      // Ignored
    }
  }

  Future<void> deleteReminder(int id) async {
    final response = await _apiService.delete<dynamic>(
      '${AppConfig.baseUrl}/MedicineReminders/$id',
      requiresAuth: true,
    );

    if (!response.success) {
      throw Exception(response.message);
    }
  }

  Future<int> createReminder(Map<String, dynamic> payload) async {
    final response = await _apiService.post<dynamic>(
      '${AppConfig.baseUrl}/MedicineReminders',
      data: payload,
      requiresAuth: true,
    );

    if (!response.success) {
      throw Exception(response.message);
    }

    final data = response.data;
    if (data is Map && data['reminderId'] != null) {
      return data['reminderId'] as int;
    }
    throw Exception('Failed to retrieve new reminder ID');
  }

  Future<void> updateReminder(int id, Map<String, dynamic> payload) async {
    final response = await _apiService.put<dynamic>(
      '${AppConfig.baseUrl}/MedicineReminders/$id',
      data: payload,
    );

    if (!response.success) {
      throw Exception(response.message);
    }
  }

  Future<void> toggleReminderStatus(int id) async {
    final response = await _apiService.patch<dynamic>(
      '${AppConfig.baseUrl}/MedicineReminders/$id/toggle',
    );

    if (!response.success) {
      throw Exception(response.message);
    }
  }
}
