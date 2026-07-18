import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:medi_ai/config/app_config.dart';
import '../../../../config/app_theme.dart';
import '../../../services/api_service.dart';
import '../../../services/medicine_reminder_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/notification_service.dart';
import '../../../widgets/app_feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'faculty_medicine_reminders_binding.dart';

class FacultyMedicineRemindersScreen extends StatefulWidget {
  const FacultyMedicineRemindersScreen({super.key});

  @override
  State<FacultyMedicineRemindersScreen> createState() =>
      _FacultyMedicineRemindersScreenState();
}

class _FacultyMedicineRemindersScreenState
    extends State<FacultyMedicineRemindersScreen> {
  final _notificationService = Get.find<NotificationService>();
  final _medicineReminderService = Get.find<MedicineReminderService>();
  final _authService = Get.find<AuthService>();

  final List<Map<String, dynamic>> reminders = [];
  bool isLoading = false;

  String get _storageKey {
    final userId = _authService.currentUser.value?.id ?? 'guest';
    return 'offline_faculty_medicine_reminders_$userId';
  }

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  final _apiService = Get.find<ApiService>();

  Future<void> _loadReminders() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? remindersJson = prefs.getString(_storageKey);

      if (remindersJson != null) {
        final List<dynamic> decoded = jsonDecode(remindersJson);
        setState(() {
          reminders
            ..clear()
            ..addAll(decoded.map((e) => Map<String, dynamic>.from(e as Map)));
        });
      } else {
        setState(() {
          reminders.clear();
        });
      }

      // Fetch from backend
      final response = await _apiService
          .get<dynamic>('${AppConfig.baseUrl}/MedicineReminders');
      if (response.success && response.data is List) {
        final List<dynamic> dbReminders = response.data;
        if (dbReminders.isNotEmpty) {
          reminders.clear();
          reminders.addAll(dbReminders
              .map((e) => _mapApiReminder(Map<String, dynamic>.from(e))));

          await prefs.setString(_storageKey, jsonEncode(reminders));
        }
      }
    } catch (e) {
      AppFeedback.error('Error', 'Failed to load reminders: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Map<String, dynamic> _mapApiReminder(Map<String, dynamic> apiReminder) {
    final timesRaw = apiReminder['times'] ?? apiReminder['Times'];

    String times;
    if (timesRaw is List) {
      times = timesRaw
          .map((e) => e.toString().replaceAll(RegExp(r'[\[\]"]'), ''))
          .join(',');
    } else if (timesRaw is String) {
      if (timesRaw.trim().startsWith('[')) {
        try {
          final List<dynamic> parsed = jsonDecode(timesRaw);
          times = parsed
              .map((e) => e.toString().replaceAll(RegExp(r'[\[\]"]'), ''))
              .join(',');
        } catch (_) {
          times = timesRaw.replaceAll(RegExp(r'[\[\]"]'), '');
        }
      } else {
        times = timesRaw.replaceAll(RegExp(r'[\[\]"]'), '');
      }
    } else {
      times = '';
    }

    return {
      'id': (apiReminder['id'] ?? apiReminder['Id'] ?? '').toString(),
      'medicineName':
          apiReminder['medicineName'] ?? apiReminder['MedicineName'] ?? '',
      'dosage': apiReminder['dosage'] ?? apiReminder['Dosage'] ?? '',
      'frequency':
          apiReminder['frequency'] ?? apiReminder['Frequency'] ?? 'Custom',
      'customFrequency':
          apiReminder['customFrequency'] ?? apiReminder['CustomFrequency'],
      'times': times,
      'startDate': (apiReminder['startDate'] ?? apiReminder['StartDate'] ?? '')
          .toString(),
      'endDate': apiReminder['endDate'] ?? apiReminder['EndDate'],
      'notes': (apiReminder['notes'] ?? apiReminder['Notes'] ?? '').toString(),
      'isActive': (apiReminder['isActive'] ?? apiReminder['IsActive']) == true,
      'isSynced': true,
    };
  }

  Map<String, dynamic> _buildApiPayload({
    required String name,
    required String dosage,
    required String frequency,
    required List<String> finalTimes,
    String? notes,
  }) {
    return {
      'medicineName': name,
      'dosage': dosage,
      'frequency': frequency,
      'customFrequency': null,
      'times': finalTimes.join(','),
      'startDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'endDate': null,
      'notes': notes ?? '',
    };
  }

  Future<void> _persistOfflineCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(reminders));

    // Sync with backend DB
    try {
      await _medicineReminderService.syncReminders(reminders);
      for (var r in reminders) {
        r['isSynced'] = true;
      }
      await prefs.setString(_storageKey, jsonEncode(reminders));
    } catch (e) {
      print(
          'Warning: Failed to sync medicine reminders to DB (Offline Mode): $e');
      for (var r in reminders) {
        if (r['isSynced'] == null) r['isSynced'] = false;
      }
      await prefs.setString(_storageKey, jsonEncode(reminders));
    }
  }

  int _generateNotificationId(String reminderId, int index) {
    // Determine a base ID from the string hash
    // We mask it to ensure positive integer limits
    // Adding 10000 offset for faculty space
    return ((reminderId.hashCode + index) & 0x7FFFFFFF) + 10000;
  }

  Future<void> _scheduleRemindersFor(Map<String, dynamic> reminder) async {
    final reminderId = reminder['id'].toString();
    final medicineName = reminder['medicineName']?.toString() ?? 'Medicine';
    final dosage = reminder['dosage']?.toString() ?? '';
    final isActive = reminder['isActive'] == true;

    List<String> timesApp;
    final timesRaw = reminder['times'];
    if (timesRaw is String) {
      if (timesRaw.trim().startsWith('[')) {
        try {
          // It's a JSON array string
          final List<dynamic> parsed = jsonDecode(timesRaw);
          timesApp = parsed.map((e) => e.toString()).toList();
        } catch (_) {
          // Fallback if parsing fails
          timesApp = timesRaw.replaceAll(RegExp(r'[\[\]"]'), '').split(',');
        }
      } else {
        // Assume comma separated
        timesApp = timesRaw.split(',');
      }
    } else if (timesRaw is List) {
      timesApp = timesRaw.map((e) => e.toString()).toList();
    } else {
      timesApp = [];
    }

    // First cancel any existing notifications for this reminder (indices 0..19)
    for (int i = 0; i < 20; i++) {
      await _notificationService
          .cancelNotification(_generateNotificationId(reminderId, i));
    }

    if (!isActive) return;

    for (int i = 0; i < timesApp.length; i++) {
      final timeStr = timesApp[i].replaceAll(RegExp(r'[\[\]"\\/]'), '').trim();
      // Parse "hh:mm a"
      final format = DateFormat('hh:mm a');
      final dt = format.parse(timeStr); // returns DateTime(1970, 1, 1, hh, mm)
      final timeOfDay = TimeOfDay(hour: dt.hour, minute: dt.minute);

      await _notificationService.scheduleNotification(
        id: _generateNotificationId(reminderId, i),
        title: 'Work/Medicine Reminder',
        body: 'It\'s time to take/do $medicineName ($dosage)',
        scheduledTime: timeOfDay,
        payload: reminderId,
      );
    }
  }

  List<String> _getTimesForFrequency(String frequency) {
    return ['08:00 AM'];
  }

  void _showAddReminderDialog(
      [Map<String, dynamic>? existingReminder, int? index]) {
    final nameController = TextEditingController(
        text: existingReminder?['medicineName'] ??
            existingReminder?['name'] ??
            '');
    final dosageController =
        TextEditingController(text: existingReminder?['dosage'] ?? '');
    final isEditing = existingReminder != null;

    // Parse initial times
    List<TimeOfDay> currentTimes = [];
    if (existingReminder != null && existingReminder['times'] != null) {
      final timesStr = existingReminder['times'].toString().split(',');
      final format = DateFormat('hh:mm a');
      for (var t in timesStr) {
        if (t.trim().isEmpty) continue;
        try {
          final dt = format.parse(t.trim());
          currentTimes.add(TimeOfDay(hour: dt.hour, minute: dt.minute));
        } catch (_) {}
      }
    }

    if (currentTimes.isEmpty) {
      currentTimes.add(const TimeOfDay(hour: 8, minute: 0));
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Reminder' : 'Add Reminder'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: 'Reminder Name'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: dosageController,
                      decoration: const InputDecoration(
                        labelText: 'Details/Dosage',
                        hintText: 'e.g., Take with food',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Reminder Times:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...currentTimes.map((time) {
                          return InputChip(
                            label: Text(time.format(context)),
                            onDeleted: () {
                              setStateDialog(() {
                                currentTimes.remove(time);
                              });
                            },
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: time,
                              );
                              if (picked != null) {
                                setStateDialog(() {
                                  final index = currentTimes.indexOf(time);
                                  currentTimes[index] = picked;
                                });
                              }
                            },
                          );
                        }),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 16),
                          label: const Text('Add Time'),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setStateDialog(() {
                                currentTimes.add(picked);
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty &&
                        dosageController.text.isNotEmpty &&
                        currentTimes.isNotEmpty) {
                      // Format times to strings
                      final formattedTimes = currentTimes.map((t) {
                        final now = DateTime.now();
                        final dt = DateTime(
                            now.year, now.month, now.day, t.hour, t.minute);
                        return DateFormat('hh:mm a').format(dt);
                      }).toList();

                      _saveReminder(
                        isEditing: isEditing,
                        reminderId: existingReminder?['id']?.toString(),
                        name: nameController.text,
                        dosage: dosageController.text,
                        frequency: 'Custom',
                        timesList: formattedTimes,
                        isActive: existingReminder?['isActive'] ?? true,
                      );
                      Navigator.of(context).pop();
                    } else if (currentTimes.isEmpty) {
                      AppFeedback.error(
                          'Error', 'Please add at least one time');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.surface,
                  ),
                  child: Text(isEditing ? 'Save' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveReminder({
    required bool isEditing,
    String? reminderId,
    required String name,
    required String dosage,
    required String frequency,
    List<String>? timesList,
    required bool isActive,
    String? notes,
  }) async {
    final finalTimes = timesList ?? _getTimesForFrequency(frequency);

    final payload = _buildApiPayload(
      name: name,
      dosage: dosage,
      frequency: frequency,
      finalTimes: finalTimes,
      notes: notes,
    );

    final newReminder = {
      'id': reminderId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'medicineName': name,
      'dosage': dosage,
      'frequency': frequency,
      'customFrequency': null,
      'times': finalTimes.join(','),
      'startDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'endDate': null,
      'notes': notes ?? '',
      'isActive': isActive,
      'isSynced': false,
    };

    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      if (isEditing && reminderId != null) {
        final parsedId = int.tryParse(reminderId);
        if (parsedId != null && parsedId <= 2147483647) {
          await _medicineReminderService.updateReminder(parsedId, payload);
          newReminder['isSynced'] = true;
        }

        final index =
            reminders.indexWhere((r) => r['id'].toString() == reminderId);
        if (index != -1) {
          reminders[index] = newReminder;
        }
      } else {
        try {
          final realId = await _medicineReminderService.createReminder(payload);
          newReminder['id'] = realId.toString();
          newReminder['isSynced'] = true;
        } catch (e) {
          print('Create failed online, falling back to offline id: $e');
        }
        reminders.add(newReminder);
      }

      await _persistOfflineCache();

      // Schedule notification
      await _scheduleRemindersFor(newReminder);

      if (mounted) {
        AppFeedback.success(
          'Success',
          isEditing
              ? 'Reminder updated successfully'
              : 'Reminder added successfully',
        );
      }
    } catch (e) {
      if (mounted) AppFeedback.error('Error', 'Failed to save reminder: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _toggleReminder(dynamic id) async {
    if (id == null) return;
    try {
      final index =
          reminders.indexWhere((r) => r['id'].toString() == id.toString());
      if (index != -1) {
        final parsedId = int.tryParse(id.toString());
        if (parsedId != null && parsedId <= 2147483647) {
          await _medicineReminderService.toggleReminderStatus(parsedId);
        }

        if (!mounted) return;
        setState(() {
          reminders[index]['isActive'] =
              !(reminders[index]['isActive'] == true);
        });

        await _persistOfflineCache();

        final updated = reminders[index];
        if (updated['isActive'] == true) {
          await _scheduleRemindersFor(updated);
        } else {
          for (int i = 0; i < 20; i++) {
            await _notificationService
                .cancelNotification(_generateNotificationId(id.toString(), i));
          }
        }
      }
    } catch (e) {
      AppFeedback.error('Error', 'Failed to toggle reminder: $e');
    }
  }

  Future<void> _deleteReminder(dynamic id) async {
    if (id == null) return;
    try {
      // Try deleting from backend if it is a numeric ID
      final parsedId = int.tryParse(id.toString());
      if (parsedId != null && parsedId <= 2147483647) {
        await _medicineReminderService.deleteReminder(parsedId);
      }

      if (!mounted) return;
      setState(() {
        reminders.removeWhere((r) => r['id'].toString() == id.toString());
      });

      await _persistOfflineCache();

      // Cancel notifications locally
      for (int i = 0; i < 20; i++) {
        await _notificationService
            .cancelNotification(_generateNotificationId(id.toString(), i));
      }

      AppFeedback.success('Deleted', 'Reminder removed');
    } catch (e) {
      AppFeedback.error('Error', 'Failed to delete reminder: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Faculty Reminders'),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.surface,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reminders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.alarm,
                          size: 64,
                          color: AppTheme.textSecondary.withOpacity(0.18)),
                      const SizedBox(height: 16),
                      Text(
                        'No reminders set',
                        style: TextStyle(
                            fontSize: 18, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add your first reminder',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = reminders[index];
                    var timesRaw = reminder['times'] ?? '';
                    List<String> times = [];
                    if (timesRaw is String) {
                      times = timesRaw
                          .replaceAll(RegExp(r'[\[\]"]'), '')
                          .split(',')
                          .where((e) => e.trim().isNotEmpty)
                          .toList();
                    } else if (timesRaw is List) {
                      times = timesRaw.map((e) => e.toString()).toList();
                    }
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.border.withOpacity(0.08)),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.textPrimary.withOpacity(0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.alarm,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        reminder['medicineName'] ??
                                            reminder['name'] ??
                                            '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${reminder['dosage'] ?? ''}',
                                        style: const TextStyle(
                                            color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: reminder['isActive'] == true,
                                  onChanged: (_) =>
                                      _toggleReminder(reminder['id']),
                                  activeColor: AppTheme.primary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (times.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: times
                                    .map((t) => Chip(
                                          label: Text(t.trim()),
                                          backgroundColor:
                                              AppTheme.primary.withOpacity(0.1),
                                          labelStyle: const TextStyle(
                                              color: AppTheme.primary),
                                        ))
                                    .toList(),
                              ),
                            if (reminder['notes'] != null &&
                                (reminder['notes'] as String).isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Notes: ${reminder['notes']}',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      _showAddReminderDialog(reminder, index),
                                  child: const Text('Edit'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      _deleteReminder(reminder['id']),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.error,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddReminderDialog(),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: AppTheme.surface),
      ),
    );
  }
}
