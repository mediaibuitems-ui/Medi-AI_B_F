import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../config/app_theme.dart';
import '../../../services/doctor_service.dart';
import '../dashboard/doctor_dashboard_controller.dart';

export 'write_prescription_binding.dart';


class WritePrescriptionScreen extends StatefulWidget {
  const WritePrescriptionScreen({super.key});

  @override
  State<WritePrescriptionScreen> createState() => _WritePrescriptionScreenState();
}

class _WritePrescriptionScreenState extends State<WritePrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();
  final List<Map<String, String>> _medications = [];

  @override
  void dispose() {
    _diagnosisController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments is Map ? Map<String, dynamic>.from(Get.arguments as Map) : <String, dynamic>{};
    final patientName = args['patientName'] ?? 'Patient';

    return Scaffold(
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
          onPressed: () => Get.back(),
        ),
        title: const Text('Write Prescription'),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
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
                      const Icon(Icons.person, color: AppTheme.primary, size: 32),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Patient',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                          Text(
                            patientName,
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
                controller: _diagnosisController,
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
                    onPressed: _addMedication,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Medicine'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_medications.isEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border.withOpacity(0.08)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.medication, size: 48, color: AppTheme.textSecondary.withOpacity(0.18)),
                          const SizedBox(height: 8),
                          Text(
                            'No medications added',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ..._medications.asMap().entries.map((entry) {
                  final index = entry.key;
                  final med = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border.withOpacity(0.08)),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.primary,
                        child: Icon(Icons.medication, color: AppTheme.surface, size: 20),
                      ),
                      title: Text(med['name']!),
                      subtitle: Text('${med['dosage']} - ${med['duration']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: AppTheme.error),
                        onPressed: () => _removeMedication(index),
                      ),
                    ),
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
                controller: _notesController,
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
                  onPressed: _savePrescription,
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
    );
  }

  void _addMedication() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final dosageController = TextEditingController();
        final durationController = TextEditingController();

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
                  setState(() {
                    _medications.add({
                      'name': nameController.text,
                      'dosage': dosageController.text,
                      'duration': durationController.text,
                    });
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

  void _removeMedication(int index) {
    setState(() {
      _medications.removeAt(index);
    });
  }

  void _savePrescription() {
    if (!_formKey.currentState!.validate()) return;

    if (_medications.isEmpty) {
      Get.snackbar(
        'Error',
        'Please add at least one medication',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.error,
        colorText: AppTheme.surface,
      );
      return;
    }


    // Note: The controller logic should ideally be in a GetxController but implemented here for simplicity
    final doctorService = Get.find<DoctorService>();
    final args = Get.arguments is Map ? Map<String, dynamic>.from(Get.arguments as Map) : <String, dynamic>{};
    final appointmentId = args['appointmentId'];
    
    if (appointmentId == null) {
        Get.snackbar('Error', 'Invalid appointment ID');
        return;
    }

    String prescriptionText = "Diagnosis: ${_diagnosisController.text}\n\nMedications:\n";
    for(var med in _medications) {
        prescriptionText += "- ${med['name']} (${med['duration']}): ${med['dosage']}\n";
    }
    if (_notesController.text.isNotEmpty) {
        prescriptionText += "\nNotes: ${_notesController.text}";
    }

    // Call API
    doctorService.addPrescription(appointmentId.toString(), prescriptionText).then((response) {
       if (response.success) {
          Get.snackbar(
            'Success',
            'Prescription saved & Appointment Completed',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppTheme.success,
            colorText: AppTheme.surface,
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            Get.back();
            // Refresh previous screen if needed (e.g. Dashboard)
            if (Get.isRegistered<DoctorDashboardController>()) {
                Get.find<DoctorDashboardController>().refresh();
            }
          });
       } else {
          Get.snackbar('Error', response.message);
       }
    }).catchError((e) {
       Get.snackbar('Error', 'Failed to save: $e');
    });
  }
}

