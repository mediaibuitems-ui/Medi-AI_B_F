import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../config/app_theme.dart';
import 'booking_settings_controller.dart';

export 'booking_settings_binding.dart';

class BookingSettingsScreen extends GetView<BookingSettingsController> {
  const BookingSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Appointment Booking Settings'),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // Appointment Settings Section
              _buildSectionCard(
                'Appointment Configuration',
                Icons.calendar_today,
                [
                  _buildSliderSetting(
                    'Appointment Duration',
                    controller.appointmentDuration.value.toDouble(),
                    15,
                    60,
                    (value) => controller.setAppointmentDuration(value.toInt()),
                    '${controller.appointmentDuration.value} minutes',
                    divisions: 9,
                  ),
                  const SizedBox(height: 16),
                  _buildSliderSetting(
                    'Max Patients Per Day',
                    controller.maxPatientsPerDay.value.toDouble(),
                    1,
                    50,
                    (value) => controller.setMaxPatientsPerDay(value.toInt()),
                    '${controller.maxPatientsPerDay.value} patients',
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchSetting(
                    'Auto Confirm Appointments',
                    controller.autoConfirmAppointments,
                    'Automatically confirm new appointment requests',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Break Time Settings Section
              _buildSectionCard(
                'Break Time Configuration',
                Icons.lunch_dining,
                [
                  _buildSwitchSetting(
                    'Enable Break Time',
                    controller.enableBreakTime,
                    'Set a break period during your working hours',
                  ),
                  const SizedBox(height: 12),
                  if (controller.enableBreakTime.value) ...[
                    _buildTimePickerSetting(
                      'Break Start Time',
                      controller.breakStartTime.value,
                      (time) {
                        controller.breakStartTime.value = time;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTimePickerSetting(
                      'Break End Time',
                      controller.breakEndTime.value,
                      (time) {
                        controller.breakEndTime.value = time;
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              
              // Reminder Settings Section
              _buildSectionCard(
                'Reminder & Notification Settings',
                Icons.notifications,
                [
                  _buildSwitchSetting(
                    'Enable Appointment Reminders',
                    controller.enableAppointmentReminders,
                    'Send reminders to patients before appointments',
                  ),
                  const SizedBox(height: 16),
                  _buildSliderSetting(
                    'Reminder Notification Time',
                    controller.reminderNotificationMinutes.value.toDouble(),
                    5,
                    120,
                    (value) => controller.setReminderMinutes(value.toInt()),
                    '${controller.reminderNotificationMinutes.value} minutes before',
                    divisions: 23,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Save Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isSaving.value
                        ? null
                        : () => controller.saveSettings(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.surface,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: AppTheme.border.withOpacity(0.35),
                    ),
                    child: controller.isSaving.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.surface,
                            ),
                          )
                        : const Text(
                            'Save Settings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Error Message
              if (controller.errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.error.withOpacity(0.2)),
                    ),
                    child: Text(
                      controller.errorMessage.value,
                      style: TextStyle(
                        color: AppTheme.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border.withOpacity(0.08)),
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
                  Icon(icon, color: AppTheme.primary, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderSetting(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
    String displayLabel, {
    int? divisions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                displayLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: AppTheme.primary,
          inactiveColor: AppTheme.primary.withOpacity(0.2),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSwitchSetting(
    String label,
    RxBool observable,
    String description,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Obx(() => Switch(
          value: observable.value,
          activeColor: AppTheme.primary,
          onChanged: (value) {
            observable.value = value;
          },
        )),
      ],
    );
  }

  Widget _buildTimePickerSetting(
    String label,
    String currentValue,
    Function(String) onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: Get.context!,
          initialTime: TimeOfDay(
            hour: int.parse(currentValue.split(':')[0]),
            minute: int.parse(currentValue.split(':')[1]),
          ),
        );
        if (picked != null) {
          final time =
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          onChanged(time);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.border.withOpacity(0.08)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentValue,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            Icon(Icons.access_time, color: AppTheme.textSecondary.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
