import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../config/app_theme.dart';
import 'controllers/today_appointments_controller.dart';
import 'package:intl/intl.dart';

export 'today_appointments_binding.dart';

class TodayAppointmentsScreen extends GetView<TodayAppointmentsController> {
  const TodayAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: const Text('Today Appointments'),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.surface,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.appointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available, size: 80, color: AppTheme.textSecondary.withOpacity(0.18)),
                const SizedBox(height: 16),
                Text(
                  'No appointments for today',
                  style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.appointments.length,
          itemBuilder: (context, index) {
            final appointment = controller.appointments[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('hh:mm a').format(appointment.dateTime),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        _buildStatusChip(appointment.status),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      'Patient name',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    Text(
                      appointment.patientName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Symptoms',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    Text(
                      appointment.symptoms ?? 'No symptoms specified',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (appointment.status == 'Pending' ||
                            appointment.status == 'Scheduled') ...[
                          OutlinedButton(
                            onPressed: () => controller.updateStatus(
                                appointment.id.toString(), 'Cancelled'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.error),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => controller.updateStatus(
                                appointment.id.toString(), 'Confirmed'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: AppTheme.surface),
                            child: const Text('Confirm'),
                          ),
                        ] else if (appointment.status == 'Confirmed') ...[
                          ElevatedButton(
                            onPressed: () => controller.updateStatus(
                                appointment.id.toString(), 'Completed'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.success,
                              foregroundColor: AppTheme.surface),
                            child: const Text('Mark as checked'),
                          ),
                        ] else if (appointment.status == 'Completed') ...[
                            Chip(
                              label: const Text('Completed'),
                              backgroundColor: AppTheme.success.withOpacity(0.15)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Scheduled':
      case 'Pending':
        color = AppTheme.warning;
        break;
      case 'Confirmed':
        color = AppTheme.primary;
        break;
      case 'Completed':
      case 'Checked':
        color = AppTheme.success;
        break;
      case 'Cancelled':
        color = AppTheme.error;
        break;
      default:
        color = AppTheme.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

}

