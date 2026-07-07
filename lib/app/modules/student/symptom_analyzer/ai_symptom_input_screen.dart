import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'ai_symptom_input_controller.dart';
import 'package:medi_ai/config/app_theme.dart';

class AiSymptomInputScreen extends GetView<AiSymptomInputController> {
  const AiSymptomInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Symptom Analyzer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Handle history
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() => Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Warning Banner
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'This tool provides general guidance, not medical advice. Consult a doctor for accurate diagnosis.',
                                  style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Section 1: Symptoms
                        Text('1. Select Your Symptoms', style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: controller.commonSymptoms.map((symptom) {
                            final isSelected = controller.selectedSymptoms.contains(symptom);
                            return FilterChip(
                              label: Text(symptom),
                              selected: isSelected,
                              onSelected: (_) => controller.toggleSymptom(symptom),
                              selectedColor: Colors.blue.shade50,
                              checkmarkColor: Colors.blue.shade700,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.blue.shade700 : Colors.black87,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected ? Colors.blue.shade200 : Colors.grey.shade300,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Section 2: Severity
                        Text('2. How severe are your symptoms?', style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8.0,
                          children: controller.severityLevels.map((severity) {
                            final isSelected = controller.selectedSeverity.value == severity;
                            return ChoiceChip(
                              label: Text(severity),
                              selected: isSelected,
                              onSelected: (_) => controller.selectSeverity(severity),
                              selectedColor: Colors.green.shade50,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.green.shade700 : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected ? Colors.green.shade300 : Colors.grey.shade300,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Section 3: Duration
                        Text('3. How long have you had these symptoms?', style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: controller.durationController,
                          decoration: InputDecoration(
                            hintText: 'e.g., 3 days, 1 week',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please specify the duration';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Section 4: Other Symptoms
                        Text('4. Any other symptoms or context?', style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: controller.otherSymptomsController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Type any additional details here...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 80), // Padding for button
                      ],
                    ),
                  ),
                ),
                if (controller.isLoading.value)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            )),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() => ElevatedButton(
              onPressed: controller.isLoading.value ? null : () => controller.analyzeSymptoms(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: controller.isLoading.value
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Analyze Symptoms', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )),
      ),
    );
  }
}
