import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../config/app_theme.dart';
import 'ai_symptom_result_controller.dart';

class AiSymptomResultScreen extends GetView<AiSymptomResultController> {
  const AiSymptomResultScreen({super.key});

  Color _getSeveritySemanticColor(String severity) {
    final s = severity.toLowerCase();
    if (s.contains('severe') || s.contains('high') || s.contains('urgent')) return AppTheme.error;
    if (s.contains('moderate') || s.contains('elevated')) return AppTheme.warning;
    return AppTheme.success;
  }

  @override
  Widget build(BuildContext context) {
    final semanticColor = _getSeveritySemanticColor(controller.severity);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: const Text('Analysis Result'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 100.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Result Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.textPrimary.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            const Icon(Icons.health_and_safety, color: AppTheme.primary),
                            const SizedBox(width: 8.0),
                            Text(
                              'AI Analysis',
                              style: AppTheme.h3,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        
                        // White Inner Box (since card is surface, make inner box slightly distinct or just bordered)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: AppTheme.background, // Contrast against surface
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildResultRow('Possible Condition:', controller.possibleCondition, AppTheme.textPrimary),
                              const Divider(height: 24.0, thickness: 1, color: AppTheme.divider),
                              _buildResultRow('Confidence Level:', controller.confidenceLevel, AppTheme.textPrimary),
                              const Divider(height: 24.0, thickness: 1, color: AppTheme.divider),
                              _buildResultRow('Severity:', controller.severity, AppTheme.textPrimary),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16.0),

                        // Urgency Paragraph
                        Text(
                          controller.urgencyMessage,
                          style: AppTheme.bodyLarge.copyWith(
                            color: semanticColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32.0),

                  // Recommendations
                  Text(
                    'Recommendations',
                    style: AppTheme.h3,
                  ),
                  const SizedBox(height: 16.0),
                  ...controller.recommendations.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle, color: AppTheme.success, size: 22),
                            const SizedBox(width: 12.0),
                            Expanded(child: Text(item, style: AppTheme.bodyMedium)),
                          ],
                        ),
                      )),
                  const SizedBox(height: 32.0),

                  // Home Care Guidance
                  Text(
                    'Home Care Guidance',
                    style: AppTheme.h3,
                  ),
                  const SizedBox(height: 16.0),
                  ...controller.homeCareGuidance.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 22),
                            const SizedBox(width: 12.0),
                            Expanded(child: Text(item, style: AppTheme.bodyMedium)),
                          ],
                        ),
                      )),
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
                child: ElevatedButton.icon(
                  onPressed: controller.bookAppointment,
                  icon: const Icon(Icons.calendar_today, size: 20),
                  label: const Text('Book an Appointment'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTheme.bodyMedium.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
