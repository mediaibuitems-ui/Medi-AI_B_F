import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../config/app_theme.dart';
import 'schedule_controller.dart';

export 'schedule_binding.dart';

class ScheduleScreen extends GetView<ScheduleController> {
  const ScheduleScreen({super.key});

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      return const TimeOfDay(hour: 9, minute: 0);
    }

    final hour = int.tryParse(parts[0]) ?? 9;
    final minute = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickTime(BuildContext context, int index, bool isStart) async {
    final item = controller.schedule[index];
    final key = isStart ? 'startTime' : 'endTime';
    final fallback = isStart ? '09:00' : '17:00';
    final raw =
        (item[key] ?? item[isStart ? 'StartTime' : 'EndTime'] ?? fallback)
            .toString();

    final picked = await showTimePicker(
      context: context,
      initialTime: _parseTime(raw),
    );

    if (picked == null) return;

    controller.updateDayTime(index,
        isStart: isStart, value: _formatTime(picked));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Set Schedule'),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadSchedule,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.schedule.isEmpty) {
          return Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(
                'No schedule configured',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                child: const Text('Load default weekly schedule'),
                onPressed: () => controller.loadSchedule(),
              )
            ]),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.textPrimary.withOpacity(0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Doctor working days',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Set the working hours for each day of the week.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: controller.schedule.length,
                itemBuilder: (context, index) {
                  final item = controller.schedule[index];
                  final day =
                      (item['dayOfWeek'] ?? item['DayOfWeek'] ?? '').toString();
                  final start =
                      (item['startTime'] ?? item['StartTime'] ?? '').toString();
                  final end =
                      (item['endTime'] ?? item['EndTime'] ?? '').toString();
                  final available = item['isAvailable'] == true ||
                      item['IsAvailable'] == true;
                  final availabilityLabel =
                      available ? 'Available' : 'Not available';
                  final availabilityColor =
                      available ? AppTheme.success : AppTheme.textSecondary;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: available ? AppTheme.surface : AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppTheme.border.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.textPrimary.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: available,
                                activeColor: AppTheme.primary,
                                onChanged: (val) {
                                  controller.updateDayAvailability(
                                      index, val ?? false);
                                },
                              ),
                              Text(_translateDay(day),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: availabilityColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  availabilityLabel,
                                  style: TextStyle(
                                    color: availabilityColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 16, color: AppTheme.textSecondary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    start.isNotEmpty && end.isNotEmpty
                                        ? '$start - $end'
                                        : 'No timing set',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      _pickTime(context, index, true),
                                  icon: const Icon(Icons.schedule, size: 16),
                                  label: const Text('Start'),
                                ),
                                const SizedBox(width: 4),
                                TextButton.icon(
                                  onPressed: () =>
                                      _pickTime(context, index, false),
                                  icon: const Icon(Icons.schedule_outlined,
                                      size: 16),
                                  label: const Text('End'),
                                ),
                              ],
                            ),
                          ),
                          if (!available)
                            Padding(
                              padding: EdgeInsets.only(left: 16.0, top: 6.0),
                              child: Text(
                                'Timing saved while the day is disabled',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isSaving.value
                    ? null
                    : () => _saveSchedule(controller),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.surface,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: controller.isSaving.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: AppTheme.surface, strokeWidth: 2))
                    : const Text('Save changes'),
              ),
            )
          ],
        );
      }),
    );
  }

  String _translateDay(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return 'Monday';
      case 'tuesday':
        return 'Tuesday';
      case 'wednesday':
        return 'Wednesday';
      case 'thursday':
        return 'Thursday';
      case 'friday':
        return 'Friday';
      case 'saturday':
        return 'Saturday';
      case 'sunday':
        return 'Sunday';
      default:
        return day;
    }
  }

  void _saveSchedule(ScheduleController controller) {
    controller.saveSchedule();
  }
}
