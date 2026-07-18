import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../config/app_theme.dart';
import 'admin_doctor_leaves_controller.dart';

class AdminDoctorLeavesScreen extends GetView<AdminDoctorLeavesController> {
  const AdminDoctorLeavesScreen({Key? key}) : super(key: key);

  void _showLeaveDialog(BuildContext context,
      {required Map<String, dynamic> leave}) {
    final formKey = GlobalKey<FormState>();
    final reasonController = TextEditingController(text: leave['reason']);
    DateTime? selectedStartDate = DateTime.parse(leave['startDate']);
    DateTime? selectedEndDate = DateTime.parse(leave['endDate']);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Leave',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Start Date Picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Start Date'),
                      subtitle: Text(DateFormat('MMM dd, yyyy')
                          .format(selectedStartDate!)),
                      trailing: const Icon(Icons.calendar_today,
                          color: AppTheme.primary),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedStartDate!,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            selectedStartDate = date;
                            // Reset end date if it's before start date
                            if (selectedEndDate != null &&
                                selectedEndDate!.isBefore(date)) {
                              selectedEndDate = null;
                            }
                          });
                        }
                      },
                    ),
                    const Divider(),

                    // End Date Picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('End Date'),
                      subtitle: Text(selectedEndDate == null
                          ? 'Select end date'
                          : DateFormat('MMM dd, yyyy')
                              .format(selectedEndDate!)),
                      trailing: const Icon(Icons.calendar_today,
                          color: AppTheme.primary),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedEndDate ?? selectedStartDate!,
                          firstDate: selectedStartDate!,
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => selectedEndDate = date);
                        }
                      },
                    ),
                    const Divider(),

                    // Reason Input
                    TextFormField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Reason for leave',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a reason';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            if (selectedStartDate == null ||
                                selectedEndDate == null) {
                              Get.snackbar(
                                'Error',
                                'Please select both start and end dates',
                                backgroundColor:
                                    AppTheme.error.withOpacity(0.1),
                                colorText: AppTheme.error,
                              );
                              return;
                            }

                            if (formKey.currentState!.validate()) {
                              Get.back();
                              controller.updateLeave(
                                leave['id'],
                                selectedStartDate!,
                                selectedEndDate!,
                                reasonController.text.trim(),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: AppTheme.surface,
                          ),
                          child: const Text('Save Changes'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Leaves'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.leaves.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_available,
                  size: 64,
                  color: AppTheme.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No leaves found',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.textSecondary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchLeaves,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.leaves.length,
            itemBuilder: (context, index) {
              final leave = controller.leaves[index];
              final startDate = DateTime.parse(leave['startDate']);
              final endDate = DateTime.parse(leave['endDate']);
              final isPast = endDate.isBefore(DateTime.now());

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isPast
                        ? Colors.grey.withOpacity(0.3)
                        : AppTheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppTheme.primary,
                                  child: Icon(Icons.medical_services,
                                      size: 16, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Dr. ${leave['doctorName']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPast
                                  ? Colors.grey.withOpacity(0.1)
                                  : AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isPast ? 'Past' : 'Upcoming',
                              style: TextStyle(
                                color: isPast ? Colors.grey : AppTheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            color: isPast ? Colors.grey : AppTheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${DateFormat('MMM dd, yyyy').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}',
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Reason:',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        leave['reason'] ?? 'No reason provided',
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      if (!isPast) ...[
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () =>
                                  _showLeaveDialog(context, leave: leave),
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit'),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () {
                                Get.defaultDialog(
                                  title: 'Delete Leave',
                                  middleText:
                                      'Are you sure you want to delete this leave?',
                                  textConfirm: 'Delete',
                                  textCancel: 'Cancel',
                                  confirmTextColor: Colors.white,
                                  buttonColor: AppTheme.error,
                                  onConfirm: () {
                                    Get.back();
                                    controller.deleteLeave(leave['id']);
                                  },
                                );
                              },
                              icon: const Icon(Icons.delete,
                                  size: 18, color: AppTheme.error),
                              label: const Text('Delete',
                                  style: TextStyle(color: AppTheme.error)),
                            ),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
