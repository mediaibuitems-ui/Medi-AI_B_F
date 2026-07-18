import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../config/app_theme.dart';
import 'medical_history_controller.dart';

class MedicalHistoryScreen extends GetView<MedicalHistoryController> {
  const MedicalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Medical History'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.medicalHistoryList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No medical history found',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.medicalHistoryList.length,
          itemBuilder: (context, index) {
            final record = controller.medicalHistoryList[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: Icon(
                    _getIconForType(record.recordType),
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  record.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${record.recordType} • ${record.diagnosisDate ?? "No Date"}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(record.id),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (record.description != null &&
                            record.description!.isNotEmpty) ...[
                          const Text(
                            'Description:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(record.description!),
                          const SizedBox(height: 8),
                        ],
                        if (record.notes != null &&
                            record.notes!.isNotEmpty) ...[
                          const Text(
                            'Notes:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(record.notes!),
                        ],
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      }),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Allergy':
        return Icons.warning_amber;
      case 'Surgery':
        return Icons.medical_services;
      case 'Immunization':
        return Icons.vaccines;
      case 'Chronic Condition':
        return Icons.healing;
      default:
        return Icons.note;
    }
  }

  void _confirmDelete(int id) {
    Get.defaultDialog(
      title: 'Delete Record',
      middleText: 'Are you sure you want to delete this record?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.deleteMedicalHistory(id);
      },
    );
  }

  void _showAddDialog() {
    Get.defaultDialog(
      title: 'Add Medical Record',
      content: Column(
        children: [
          Obx(() => DropdownButtonFormField<String>(
                value: controller.recordType.value,
                items: controller.recordTypes
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => controller.recordType.value = val!,
                decoration: const InputDecoration(labelText: 'Record Type'),
              )),
          TextField(
            controller: controller.titleController,
            decoration: const InputDecoration(
                labelText: 'Title (e.g., Peanut Allergy)'),
          ),
          TextField(
            controller: controller.descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 2,
          ),
          TextField(
            controller: controller.notesController,
            decoration: const InputDecoration(labelText: 'Notes'),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          Obx(() => ListTile(
                title: Text(controller.diagnosisDate.value == null
                    ? 'Select Date'
                    : DateFormat('yyyy-MM-dd')
                        .format(controller.diagnosisDate.value!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: Get.context!,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    controller.diagnosisDate.value = date;
                  }
                },
              )),
        ],
      ),
      textConfirm: 'Save',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () => controller.addMedicalHistory(),
    );
  }
}
