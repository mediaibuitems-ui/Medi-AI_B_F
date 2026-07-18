import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../config/app_theme.dart';
import 'write_prescription_controller.dart';

export 'write_prescription_binding.dart';

class WritePrescriptionScreen extends GetView<WritePrescriptionController> {
  const WritePrescriptionScreen({super.key});

  Future<bool> _onWillPop() async {
    if (!controller.hasUnsavedData) return true;
    
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Discard prescription?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: AppTheme.surface,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, dynamic result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop) {
          Get.back();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          leading: IconButton(
            icon: Image.asset(
              'assets/images/logos/buitems-logo-png_seeklogo-273407.png',
              width: 32,
              height: 32,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.arrow_back);
              },
            ),
            onPressed: () async {
              if (await _onWillPop()) {
                Get.back();
              }
            },
          ),
          title: const Text('Write Prescription'),
          backgroundColor: AppTheme.primary,
          foregroundColor: AppTheme.surface,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
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
                    child: Row(
                      children: [
                        const Icon(Icons.person,
                            color: AppTheme.primary, size: 32),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Patient',
                              style: TextStyle(
                                  fontSize: 12, color: AppTheme.textSecondary),
                            ),
                            Text(
                              controller.patientName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Diagnosis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.diagnosisController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter diagnosis...',
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter diagnosis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Medications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _addMedication(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Medicine'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Obx(() {
                  if (controller.medications.isEmpty) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppTheme.border.withOpacity(0.08)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.medication,
                                  size: 48,
                                  color: AppTheme.textSecondary.withOpacity(0.18)),
                              const SizedBox(height: 8),
                              const Text(
                                'No medications added',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: controller.medications.asMap().entries.map((entry) {
                      final index = entry.key;
                      final med = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppTheme.border.withOpacity(0.08)),
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppTheme.primary,
                            child: Icon(Icons.medication,
                                color: AppTheme.surface, size: 20),
                          ),
                          title: Text(med['name']!),
                          subtitle: Text(
                              '${med['dosage']} - ${med['duration']}\nFreq: ${med['frequency'] ?? 'N/A'} | Inst: ${med['instructions'] ?? 'None'}'),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: AppTheme.error),
                            onPressed: () => controller.removeMedication(index),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),
                const SizedBox(height: 20),
                const Text(
                  'Additional Notes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.notesController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Enter any additional notes or instructions...',
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: controller.savePrescription,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Prescription'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addMedication(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final dosageController = TextEditingController();
        final durationController = TextEditingController();
        final frequencyController = TextEditingController();
        final instructionsController = TextEditingController();

        return AlertDialog(
          title: const Text('Add Medication'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Medicine Name',
                    hintText: 'e.g., Paracetamol 500mg',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dosageController,
                  decoration: const InputDecoration(
                    labelText: 'Dosage',
                    hintText: 'e.g., Twice a day after meals',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration',
                    hintText: 'e.g., 5 days',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: frequencyController,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    hintText: 'e.g., Every 8 hours',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: instructionsController,
                  decoration: const InputDecoration(
                    labelText: 'Instructions',
                    hintText: 'e.g., Take after meals',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    dosageController.text.isNotEmpty &&
                    durationController.text.isNotEmpty) {
                  controller.addMedication({
                    'name': nameController.text,
                    'dosage': dosageController.text,
                    'duration': durationController.text,
                    'frequency': frequencyController.text,
                    'instructions': instructionsController.text,
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.surface,
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
