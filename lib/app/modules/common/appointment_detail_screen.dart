import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:medi_ai/app/data/models/appointment.dart';
import 'package:medi_ai/app/services/api_service.dart';
import 'package:medi_ai/config/app_config.dart';
// removed unused imports
import 'package:medi_ai/app/modules/student/dashboard/student_dashboard_controller.dart';
import 'package:medi_ai/app/modules/faculty/dashboard/faculty_dashboard_controller.dart';
import 'package:medi_ai/app/widgets/prescription_card.dart';

class AppointmentDetailScreen extends StatelessWidget {
  const AppointmentDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arg = Get.arguments as Map<String, dynamic>?;
    final Appointment? appointment =
        arg != null ? arg['appointment'] as Appointment? : null;

    if (appointment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Appointment')),
        body: const Center(child: Text('No appointment data provided')),
      );
    }

    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    final bool canEdit = _canEdit(appointment);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditDialog(context, appointment),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient: ${appointment.patientName}',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text('Doctor: Dr. ${appointment.doctorName}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Reason: ${appointment.reason}'),
            const SizedBox(height: 8),
            Text('Date: ${dateFormat.format(appointment.appointmentDate)}'),
            const SizedBox(height: 8),
            Text('Time: ${timeFormat.format(appointment.appointmentDate)}'),
            const SizedBox(height: 8),
            Text('Status: ${appointment.status}'),
            const SizedBox(height: 12),
            Text('Symptoms: ${appointment.symptoms ?? '-'}'),
            const SizedBox(height: 12),
            Text('Notes: ${appointment.notes ?? '-'}'),
            if (appointment.prescription != null &&
                appointment.prescription!.isNotEmpty) ...[
              const SizedBox(height: 16),
              PrescriptionCard(rawPrescription: appointment.prescription!),
            ],
            const Spacer(),
            Row(
              children: [
                if (canEdit)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showEditDialog(context, appointment),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Appointment'),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _cancelAppointment(appointment),
                    child: const Text('Cancel Appointment'),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  bool _canEdit(Appointment appointment) {
    if (appointment.status != 'Pending') return false;
    final diff = appointment.dateTime.difference(DateTime.now()).inMinutes;
    return diff > 30;
  }

  void _cancelAppointment(Appointment appointment) async {
    try {
      // try student controller
      final studentCtrl = Get.isRegistered<StudentDashboardController>()
          ? Get.find<StudentDashboardController>()
          : null;
      final facultyCtrl = Get.isRegistered<FacultyDashboardController>()
          ? Get.find<FacultyDashboardController>()
          : null;

      if (studentCtrl != null) {
        await studentCtrl.cancelAppointment(appointment.id);
      } else if (facultyCtrl != null) {
        await facultyCtrl.cancelAppointment(appointment.id);
      } else {
        final api = Get.find<ApiService>();
        final response = await api
            .delete('${AppConfig.baseUrl}/Appointments/${appointment.id}');
        if (response.success) {
          Get.snackbar('Success', 'Appointment cancelled');
        } else {
          Get.snackbar('Error', response.message);
        }
      }
      Get.back();
    } catch (e) {
      Get.snackbar('Error', 'Failed to cancel appointment');
    }
  }

  void _showEditDialog(BuildContext context, Appointment appointment) {
    final dateController = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(appointment.appointmentDate));
    final timeController = TextEditingController(
        text: DateFormat('HH:mm').format(appointment.appointmentDate));
    final symptomsController =
        TextEditingController(text: appointment.symptoms ?? '');
    final notesController =
        TextEditingController(text: appointment.notes ?? '');

    DateTime selectedDate = appointment.appointmentDate;

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Appointment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                    labelText: 'Date', suffixIcon: Icon(Icons.calendar_today)),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (date != null) {
                    selectedDate = date;
                    dateController.text = DateFormat('yyyy-MM-dd').format(date);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                    labelText: 'Time', suffixIcon: Icon(Icons.access_time)),
                readOnly: true,
                onTap: () async {
                  final currentT =
                      TimeOfDay.fromDateTime(appointment.appointmentDate);
                  final time = await showTimePicker(
                      context: context, initialTime: currentT);
                  if (time != null) {
                    final dt = DateTime(0, 0, 0, time.hour, time.minute);
                    timeController.text = DateFormat('HH:mm').format(dt);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                  controller: symptomsController,
                  decoration: const InputDecoration(labelText: 'Symptoms'),
                  maxLines: 2),
              const SizedBox(height: 16),
              TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              // delegate to controller if available
              final studentCtrl = Get.isRegistered<StudentDashboardController>()
                  ? Get.find<StudentDashboardController>()
                  : null;
              final facultyCtrl = Get.isRegistered<FacultyDashboardController>()
                  ? Get.find<FacultyDashboardController>()
                  : null;

              if (studentCtrl != null) {
                await studentCtrl.updateAppointment(
                  appointment.id,
                  appointment.doctorId,
                  selectedDate,
                  timeController.text,
                  symptomsController.text,
                  notesController.text,
                );
              } else if (facultyCtrl != null) {
                await facultyCtrl.updateAppointment(
                  appointment.id,
                  appointment.doctorId,
                  selectedDate,
                  timeController.text,
                  symptomsController.text,
                  notesController.text,
                );
              } else {
                final api = Get.find<ApiService>();
                final dateTimeStr =
                    '${DateFormat('yyyy-MM-dd').format(selectedDate)}T${timeController.text}:00';
                final response = await api.put(
                    '${AppConfig.baseUrl}/Appointments/${appointment.id}',
                    data: {
                      'doctorId': appointment.doctorId,
                      'dateTime': dateTimeStr,
                      'symptoms': symptomsController.text,
                      'notes': notesController.text,
                    });
                if (response.success) {
                  Get.snackbar('Success', 'Appointment updated');
                } else {
                  Get.snackbar('Error', response.message);
                }
              }

              if (Get.isDialogOpen ?? false) Get.back();
              Get.back();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
