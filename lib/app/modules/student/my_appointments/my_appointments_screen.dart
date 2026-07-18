import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../../config/app_theme.dart';
import 'my_appointments_controller.dart';

export 'my_appointments_binding.dart';

class MyAppointmentsScreen extends GetView<MyAppointmentsController> {
  const MyAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Appointments'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.isNotEmpty) {
          return Center(
              child: Text(controller.error.value,
                  style: const TextStyle(color: Colors.red)));
        }

        if (controller.appointments.isEmpty) {
          return const Center(child: Text('No appointments found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.appointments.length,
          itemBuilder: (context, index) {
            final apt = controller.appointments[index];
            final dateStr =
                DateFormat('MMM dd, yyyy - hh:mm a').format(apt.dateTime);
                
            final canCancel = apt.status.toLowerCase() != 'completed' && apt.status.toLowerCase() != 'cancelled';

            final cardContent = Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child:
                      const Icon(Icons.calendar_today, color: AppTheme.primary),
                ),
                title: Text(apt.doctorName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateStr),
                    if (apt.status.isNotEmpty)
                      Text(apt.status,
                          style: TextStyle(
                              color: _getStatusColor(apt.status),
                              fontWeight: FontWeight.bold)),
                  ],
                ),
                isThreeLine: true,
                onTap: () {
                  // Handle detailed view if needed
                },
              ),
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: canCancel 
                ? Slidable(
                    key: ValueKey(apt.id),
                    endActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (_) {
                            _showCancelDialog(context, apt.id);
                          },
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.cancel,
                          label: 'Cancel',
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                      ],
                    ),
                    child: cardContent,
                  )
                : cardContent,
            );
          },
        );
      }),
    );
  }

  void _showCancelDialog(BuildContext context, String appointmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.cancelAppointment(appointmentId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
