import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../config/app_theme.dart';
import 'ai_symptom_input_controller.dart';

class AiSymptomInputScreen extends GetView<AiSymptomInputController> {
  const AiSymptomInputScreen({super.key});

  Color _getSeveritySemanticColor(String severity) {
    if (severity == 'Mild') return AppTheme.success;
    if (severity == 'Moderate') return AppTheme.warning;
    if (severity == 'Severe') return AppTheme.error;
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: const Text('AI Symptom Analyzer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Get.toNamed('/symptom-analyzer-history');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100), // Space for CTA
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Disclaimer Banner
                  Container(
                    margin: const EdgeInsets.all(16.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.textPrimary.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Text(
                            'This tool provides general guidance, not medical advice. Consult a doctor for accurate diagnosis.',
                            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Section 1: Symptoms
                  _buildSectionLabel('1. Select Your Symptoms'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: controller.commonSymptoms.map((symptom) {
                        return Obx(() {
                          final isSelected = controller.selectedSymptoms.contains(symptom);
                          return InkWell(
                            onTap: () => controller.toggleSymptom(symptom),
                            borderRadius: BorderRadius.circular(24.0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primary.withOpacity(0.1) : AppTheme.surface,
                                borderRadius: BorderRadius.circular(24.0),
                                border: Border.all(
                                  color: isSelected ? AppTheme.primary : AppTheme.border,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected) ...[
                                    const Icon(Icons.check, size: 16, color: AppTheme.primary),
                                    const SizedBox(width: 8.0),
                                  ],
                                  Text(
                                    symptom,
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        });
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Section 2: Severity
                  _buildSectionLabel('2. How severe are your symptoms?'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: controller.severityLevels.map((severity) {
                        return Obx(() {
                          final isSelected = controller.selectedSeverity.value == severity;
                          final semanticColor = _getSeveritySemanticColor(severity);
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: InkWell(
                                onTap: () => controller.selectSeverity(severity),
                                borderRadius: BorderRadius.circular(24.0),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                                  decoration: BoxDecoration(
                                    color: isSelected ? semanticColor.withOpacity(0.1) : AppTheme.surface,
                                    borderRadius: BorderRadius.circular(24.0),
                                    border: Border.all(
                                      color: isSelected ? semanticColor : AppTheme.border,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isSelected) ...[
                                        Icon(Icons.check, size: 16, color: semanticColor),
                                        const SizedBox(width: 8.0),
                                      ],
                                      Text(
                                        severity,
                                        style: AppTheme.bodyMedium.copyWith(
                                          color: isSelected ? semanticColor : AppTheme.textPrimary,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        });
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Section 3: Duration
                  _buildSectionLabel('3. How long have you had these symptoms?'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: TextField(
                      controller: controller.durationController,
                      decoration: const InputDecoration(
                        hintText: 'e.g., 3 days, since this morning',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Section 4: Context
                  _buildSectionLabel('4. Any other symptoms or context?'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: TextField(
                      controller: controller.additionalContextController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Type any additional details here...',
                      ),
                    ),
                  ),

                  // Error State
                  Obx(() {
                    if (controller.error.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: AppTheme.error),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppTheme.error),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: Text(
                                  controller.error.value,
                                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),

                  const SizedBox(height: 32.0),
                ],
              ),
            ),
            
            // Primary CTA
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                color: AppTheme.background,
                child: Obx(() {
                  final bool isValid = controller.selectedSymptoms.isNotEmpty;
                  return ElevatedButton(
                    onPressed: isValid && !controller.isLoading.value ? controller.analyzeSymptoms : null,
                    child: const Text('Analyze Symptoms'),
                  );
                }),
              ),
            ),

            // Loading Shimmer Overlay
            Obx(() {
              if (controller.isLoading.value) {
                return Container(
                  color: AppTheme.background.withOpacity(0.9),
                  child: Shimmer.fromColors(
                    baseColor: AppTheme.border,
                    highlightColor: AppTheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(height: 80, decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12))),
                          const SizedBox(height: 24),
                          Container(height: 24, width: 200, color: AppTheme.surface),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(6, (index) => Container(height: 40, width: 100, decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20)))),
                          ),
                          const SizedBox(height: 32),
                          Container(height: 24, width: 250, color: AppTheme.surface),
                          const SizedBox(height: 16),
                          Row(
                            children: List.generate(3, (index) => Expanded(child: Container(margin: const EdgeInsets.only(right: 8), height: 48, decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(24))))),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 16.0),
      child: Text(
        text,
        style: AppTheme.h3,
      ),
    );
  }
}
