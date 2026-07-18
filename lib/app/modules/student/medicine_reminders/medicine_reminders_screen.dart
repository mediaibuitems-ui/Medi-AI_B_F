import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:medi_ai/config/app_config.dart';
import '../../../../config/app_theme.dart';
import '../../../services/api_service.dart';
import '../../../services/medicine_reminder_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/app_feedback.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../data/models/medicine_reminder.dart';

export 'medicine_reminders_binding.dart';

class MedicineRemindersScreen extends StatefulWidget {
  const MedicineRemindersScreen({super.key});

  @override
  State<MedicineRemindersScreen> createState() =>
      _MedicineRemindersScreenState();
}

class _MedicineRemindersScreenState extends State<MedicineRemindersScreen> {
  final _notificationService = Get.find<NotificationService>();
  final _medicineReminderService = Get.find<MedicineReminderService>();
  final _apiService = Get.find<ApiService>();
  final _authService = Get.find<AuthService>();

  final List<MedicineReminder> reminders = [];
  bool isLoading = false;

  String get _storageKey {
    final userId = _authService.currentUser.value?.id ?? 'guest';
    return 'offline_medicine_reminders_$userId';
  }

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      await _loadOfflineReminders();

      // Also fetch from backend to keep sync
      final response = await _apiService
          .get<dynamic>('${AppConfig.baseUrl}/MedicineReminders');
      if (response.success && response.data is List) {
        final List<dynamic> dbReminders = response.data;
        if (dbReminders.isNotEmpty) {
          reminders.clear();
          reminders.addAll(dbReminders
              .map((e) => _mapApiReminder(Map<String, dynamic>.from(e))));

          // Don't call _persistOfflineCache() here to avoid recursive sync loop
          if (!Hive.isBoxOpen(_storageKey)) {
            await Hive.openBox<MedicineReminder>(_storageKey);
          }
          final box = Hive.box<MedicineReminder>(_storageKey);
          await box.clear();
          await box.addAll(reminders);
        }
      }
    } catch (e) {
      print('Error loading reminders from DB: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadOfflineReminders() async {
    if (!Hive.isBoxOpen(_storageKey)) {
      await Hive.openBox<MedicineReminder>(_storageKey);
    }
    final box = Hive.box<MedicineReminder>(_storageKey);
    if (!mounted) return;
    setState(() {
      reminders.clear();
      reminders.addAll(box.values);
    });
  }

  Future<void> _persistOfflineCache() async {
    if (!Hive.isBoxOpen(_storageKey)) {
      await Hive.openBox<MedicineReminder>(_storageKey);
    }
    final box = Hive.box<MedicineReminder>(_storageKey);
    await box.clear();
    await box.addAll(reminders);
    
    // Sync via connectivity queue
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      try {
        await _medicineReminderService.syncPendingReminders();
        // Reload from box after sync to get updated real IDs
        if (!mounted) return;
        setState(() {
          reminders.clear();
          reminders.addAll(box.values);
        });
      } catch (e) {
        print('Warning: Failed to sync medicine reminders to DB: $e');
      }
    }
  }

  MedicineReminder _mapApiReminder(Map<String, dynamic> apiReminder) {
    final timesRaw = apiReminder['times'] ?? apiReminder['Times'];

    List<String> timesList = [];
    if (timesRaw is List) {
      timesList = timesRaw.map((e) => e.toString().replaceAll(RegExp(r'[\[\]"]'), '')).toList();
    } else if (timesRaw is String) {
      if (timesRaw.trim().startsWith('[')) {
        try {
          final List<dynamic> parsed = jsonDecode(timesRaw);
          timesList = parsed.map((e) => e.toString().replaceAll(RegExp(r'[\[\]"]'), '')).toList();
        } catch (_) {
          timesList = timesRaw.replaceAll(RegExp(r'[\[\]"]'), '').split(',').where((e) => e.isNotEmpty).toList();
        }
      } else {
        timesList = timesRaw.replaceAll(RegExp(r'[\[\]"]'), '').split(',').where((e) => e.isNotEmpty).toList();
      }
    }
    
    final startDateStr = (apiReminder['startDate'] ?? apiReminder['StartDate'] ?? '').toString();
    DateTime startDate = DateTime.now();
    if (startDateStr.isNotEmpty) {
      try { startDate = DateTime.parse(startDateStr); } catch (_) {}
    }

    return MedicineReminder(
      id: (apiReminder['id'] ?? apiReminder['Id'] ?? '').toString(),
      medicineName: apiReminder['medicineName'] ?? apiReminder['MedicineName'] ?? '',
      dosage: apiReminder['dosage'] ?? apiReminder['Dosage'] ?? '',
      times: timesList,
      days: [],
      startDate: startDate,
      endDate: null,
      isActive: (apiReminder['isActive'] ?? apiReminder['IsActive']) == true,
      notes: (apiReminder['notes'] ?? apiReminder['Notes'] ?? '').toString(),
      isSynced: true,
    );
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

  int _generateNotificationId(String reminderId, int index) {
    // Determine a base ID from the string hash
    // We mask it to ensure positive integer limits
    return (reminderId.hashCode + index) & 0x7FFFFFFF;
  }

  Future<void> _scheduleRemindersFor(MedicineReminder reminder) async {
    final reminderId = reminder.id.toString();
    final medicineName = reminder.medicineName;
    final dosage = reminder.dosage;
    final isActive = reminder.isActive == true;

    List<String> timesApp = reminder.times;

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
        title: 'Medicine Reminder',
        body: 'It\'s time to take $medicineName ($dosage)',
        scheduledTime: timeOfDay,
        payload: reminderId,
      );
    }
  }

  // Helper moved or removed if unused, but keeping simple fallback just in case
  List<String> _getTimesForFrequency(String frequency) {
    return ['08:00 AM'];
  }

  Future<void> _showAddReminderDialog(
      [MedicineReminder? existingReminder, int? index]) async {
    final nameController = TextEditingController(
        text: existingReminder?.medicineName ?? '');
    final dosageController =
        TextEditingController(text: existingReminder?.dosage ?? '');
    final isEditing = existingReminder != null;

    // Parse initial times
    List<TimeOfDay> currentTimes = [];
    if (existingReminder != null && existingReminder.times.isNotEmpty) {
      final timesStr = existingReminder.times;
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

    try {
      await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: Text(isEditing
                    ? 'Edit Medicine Reminder'
                    : 'Add Medicine Reminder'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Medicine Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: dosageController,
                        decoration: const InputDecoration(
                          labelText: 'Dosage',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., 500mg',
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
                          reminderId: existingReminder?.id.toString(),
                          name: nameController.text,
                          dosage: dosageController.text,
                          frequency: 'Custom',
                          timesList: formattedTimes,
                          isActive: existingReminder?.isActive ?? true,
                        );
                        Navigator.of(context).pop();
                      } else if (currentTimes.isEmpty) {
                        AppFeedback.error(
                            'Error', 'Please add at least one time');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isEditing ? 'Save' : 'Add'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      dosageController.dispose();
    }
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

    // Temporary offline ID is a negative number
    final String tempId = (-DateTime.now().millisecondsSinceEpoch).toString();
    var newReminder = MedicineReminder(
      id: reminderId ?? tempId,
      medicineName: name,
      dosage: dosage,
      times: finalTimes,
      days: [],
      startDate: DateTime.now(),
      notes: notes ?? '',
      isActive: isActive,
      isSynced: false,
    );

    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      if (isEditing && reminderId != null) {
        final parsedId = int.tryParse(reminderId);
        if (parsedId != null && parsedId <= 2147483647 && parsedId > 0) {
          try {
            await _medicineReminderService.updateReminder(parsedId, payload);
            newReminder.isSynced = true;
          } catch(e) {}
        }

        final index =
            reminders.indexWhere((r) => r.id.toString() == reminderId);
        if (index != -1) {
          reminders[index] = newReminder;
        }
      } else {
        try {
          final realId = await _medicineReminderService.createReminder(payload);
          newReminder.id = realId.toString();
          newReminder.isSynced = true;
        } catch (e) {
          print('Create failed online, falling back to offline id: $e');
        }
        reminders.add(newReminder);
      }

      await _persistOfflineCache();

      // Schedule notification
      await _scheduleRemindersFor(newReminder);

      AppFeedback.success(
        'Success',
        isEditing
            ? 'Medicine reminder updated successfully'
            : 'Medicine reminder added successfully',
      );
    } catch (e) {
      AppFeedback.error('Error', 'Failed to save reminder: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _toggleReminder(dynamic id) async {
    if (id == null) return;
    try {
      final index =
          reminders.indexWhere((r) => r.id.toString() == id.toString());
      if (index == -1) return;

      final parsedId = int.tryParse(id.toString());
      if (parsedId != null && parsedId <= 2147483647) {
        await _medicineReminderService.toggleReminderStatus(parsedId);
      }

      if (!mounted) return;
      setState(() {
        reminders[index].isActive = !(reminders[index].isActive == true);
      });

      await _persistOfflineCache();

      final updated = reminders[index];
      if (updated.isActive == true) {
        await _scheduleRemindersFor(updated);
      } else {
        for (int i = 0; i < 6; i++) {
          await _notificationService
              .cancelNotification(_generateNotificationId(id.toString(), i));
        }
      }
    } catch (e) {
      AppFeedback.error('Error', 'Failed to toggle reminder: $e');
    }
  }

  Future<void> _deleteReminder(dynamic id) async {
    if (id == null) return;
    try {
      // Try deleting from backend if it is a numeric ID (not a timestamp)
      final parsedId = int.tryParse(id.toString());
      if (parsedId != null && parsedId <= 2147483647) {
        await _medicineReminderService.deleteReminder(parsedId);
      }

      if (!mounted) return;
      setState(() {
        reminders.removeWhere((r) => r.id.toString() == id.toString());
      });

      await _persistOfflineCache();

      // Cancel notifications locally
      for (int i = 0; i < 6; i++) {
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
        title: const Text('Medicine Reminders'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reminders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medication, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No medicine reminders yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap + to add your first reminder',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = reminders[index];
                    List<String> times = reminder.times;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
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
                                    Icons.medication,
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
                                        reminder.medicineName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${reminder.dosage} • Custom',
                                        style:
                                            const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: reminder.isActive == true,
                                  onChanged: (_) =>
                                      _toggleReminder(reminder.id),
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
                            if (reminder.notes != null &&
                                reminder.notes!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Notes: ${reminder.notes}',
                                style: const TextStyle(color: Colors.grey),
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
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () =>
                                      _deleteReminder(reminder.id),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
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
        child: const Icon(Icons.add),
      ),
    );
  }
}
