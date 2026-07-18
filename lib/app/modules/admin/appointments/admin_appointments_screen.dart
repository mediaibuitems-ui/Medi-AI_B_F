import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:medi_ai/app/data/models/appointment.dart';
import 'package:medi_ai/config/app_theme.dart';
import 'admin_appointments_controller.dart';

class AdminAppointmentsScreen extends GetView<AdminAppointmentsController> {
  const AdminAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('System Appointments'),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Obx(() => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: controller.filterOptions.map((filter) {
                      final isSelected =
                          controller.selectedFilter.value == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (_) => controller.setFilter(filter),
                          selectedColor: AppTheme.primary.withOpacity(0.2),
                          checkmarkColor: AppTheme.primary,
                        ),
                      );
                    }).toList(),
                  ),
                )),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.filteredAppointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy,
                    size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text(
                  'No appointments found',
                  style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadAppointments,
          child: ListView.builder(
            controller: controller.scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: controller.filteredAppointments.length + (controller.hasMore.value ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == controller.filteredAppointments.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final appointment = controller.filteredAppointments[index];
              return _buildAppointmentCard(appointment);
            },
          ),
        );
      }),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    Color statusColor;
    switch (appointment.status.toLowerCase()) {
      case 'confirmed':
        statusColor = AppTheme.success;
        break;
      case 'completed':
        statusColor = AppTheme.primary;
        break;
      case 'cancelled':
        statusColor = AppTheme.error;
        break;
      default:
        statusColor = AppTheme.warning;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => controller.viewAppointmentDetails(appointment),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Patient: ${appointment.patientName}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      appointment.status,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.medical_services,
                      size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Dr. ${appointment.doctorName}',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM dd, yyyy - hh:mm a')
                        .format(appointment.appointmentDate),
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () =>
                        controller.viewAppointmentDetails(appointment),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View Details'),
                  ),
                  if (appointment.status != 'Cancelled')
                    TextButton.icon(
                      onPressed: () {
                        Get.dialog(
                          AlertDialog(
                            title: const Text('Cancel Appointment'),
                            content: const Text(
                                'Are you sure you want to cancel this appointment?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Get.back(),
                                  child: const Text('No')),
                              ElevatedButton(
                                onPressed: () {
                                  Get.back();
                                  controller.deleteAppointment(
                                      appointment.id.toString());
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.error),
                                child: const Text('Yes, Cancel'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.cancel,
                          size: 18, color: AppTheme.error),
                      label: const Text('Cancel',
                          style: TextStyle(color: AppTheme.error)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
