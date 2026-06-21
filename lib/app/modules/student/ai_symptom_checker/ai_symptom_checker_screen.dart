import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../config/app_theme.dart';
import 'ai_symptom_checker_controller.dart';

class AiSymptomCheckerScreen extends GetView<SymptomCheckerController> {
  const AiSymptomCheckerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('AI Symptom Analyzer'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'View History',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => _showHistorySheet(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildWarningCard(),
          const SizedBox(height: 24),
          _buildSymptomsSection(),
          const SizedBox(height: 24),
          _buildSeveritySection(),
          const SizedBox(height: 24),
          _buildDurationSection(),
          const SizedBox(height: 24),
          _buildAdditionalSymptomsField(),
          const SizedBox(height: 24),
          _buildAnalyzeButton(),
          const SizedBox(height: 24),
          _buildResultArea(context),
        ],
      ),
    );
  }

  Widget _buildWarningCard() {
    return Card(
      color: Colors.orange[50],
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.orange[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'This is not a substitute for professional medical advice. Consult a doctor for accurate diagnosis.',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Your Symptoms',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.commonSymptoms.map((symptom) {
              final isSelected = controller.selectedSymptoms.contains(symptom);
              return FilterChip(
                label: Text(symptom),
                selected: isSelected,
                onSelected: (_) => controller.toggleSymptom(symptom),
                selectedColor: AppTheme.primary.withOpacity(0.16),
                checkmarkColor: AppTheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primary : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: isSelected ? AppTheme.primary : Colors.grey.shade300,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSeveritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Severity',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Obx(
          () => Wrap(
            spacing: 10,
            runSpacing: 10,
            children: controller.severityOptions.map((severity) {
              final isSelected = controller.selectedSeverity.value == severity;
              final config = _severityConfig(severity);
              return ChoiceChip(
                label: Text(severity),
                selected: isSelected,
                onSelected: (_) => controller.setSeverity(severity),
                selectedColor: config.background,
                labelStyle: TextStyle(
                  color: isSelected ? config.foreground : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: isSelected ? config.border : Colors.grey.shade300,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Duration',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Obx(
          () => DropdownButtonFormField<String>(
            value: controller.durationOptions.contains(controller.selectedDuration.value)
                ? controller.selectedDuration.value
                : controller.durationOptions.first,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            ),
            items: controller.durationOptions
                .map(
                  (duration) => DropdownMenuItem<String>(
                    value: duration,
                    child: Text(duration),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                controller.setDuration(value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalSymptomsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Describe Additional Symptoms',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller.symptomsController,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
            hintText: 'Describe any other symptoms you\'re experiencing...',
            contentPadding: const EdgeInsets.all(16),
          ),
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    return Obx(
      () => ElevatedButton(
        onPressed: controller.isAnalyzing.value ? null : controller.analyzeSymptoms,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: controller.isAnalyzing.value
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Analyzing...'),
                ],
              )
            : const Text(
                'Analyze Symptoms',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildResultArea(BuildContext context) {
    return Obx(() {
      if (controller.isAnalyzing.value) {
        return _buildShimmerResultCard();
      }

      final result = controller.analysisResult.value;
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1,
            child: child,
          ),
        ),
        child: result == null
            ? const SizedBox.shrink()
            : _buildResultCard(context, result),
      );
    });
  }

  Widget _buildShimmerResultCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerLine(widthFactor: 0.45, height: 22),
              const SizedBox(height: 18),
              _buildShimmerLine(widthFactor: 0.8),
              const SizedBox(height: 12),
              _buildShimmerLine(widthFactor: 0.7),
              const SizedBox(height: 12),
              _buildShimmerLine(widthFactor: 0.9),
              const SizedBox(height: 22),
              _buildShimmerLine(widthFactor: 0.5),
              const SizedBox(height: 10),
              _buildShimmerLine(widthFactor: 0.95, height: 16),
              const SizedBox(height: 10),
              _buildShimmerLine(widthFactor: 0.88, height: 16),
              const SizedBox(height: 10),
              _buildShimmerLine(widthFactor: 0.8, height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLine({required double widthFactor, double height = 14}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 280 * widthFactor,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, Map<String, dynamic> result) {
    final severityText = result['severity']?.toString() ?? 'Moderate';
    final config = _severityConfig(severityText);

    return Card(
      key: ValueKey<String>('result-${result['condition']}-$severityText'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: config.border),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [config.background, config.background.withOpacity(0.45)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: config.foreground.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(config.icon, color: config.foreground),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Analysis Result',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.72),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildResultRow('Possible Condition', result['condition'].toString()),
                  _buildResultRow('Confidence Level', result['confidence'].toString()),
                  _buildResultRow('Severity', severityText),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              config.summary,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: config.foreground,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Recommendations',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (result['recommendations'] != null)
              ...(result['recommendations'] as List).map(
                (rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, size: 18, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(rec.toString())),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              config.actionTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: config.foreground,
              ),
            ),
            const SizedBox(height: 8),
            if (result['whenToSeeDoctor'] != null)
              ...(result['whenToSeeDoctor'] as List).map(
                (warning) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 18, color: config.foreground),
                      const SizedBox(width: 8),
                      Expanded(child: Text(warning.toString())),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.bookAppointment),
                icon: const Icon(Icons.calendar_month_rounded),
                label: const Text('Book an Appointment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: config.foreground,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _showHistorySheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'History',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Obx(
                        () {
                          if (controller.isLoadingHistory.value) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (controller.historyItems.isEmpty) {
                            return const Center(
                              child: Text('No previous checks yet.'),
                            );
                          }

                          return ListView.separated(
                            controller: scrollController,
                            itemCount: controller.historyItems.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, index) {
                              final item = controller.historyItems[index];
                              final symptoms = (item['symptoms'] ?? item['Symptoms'] ?? '').toString();
                              final condition = (item['condition'] ?? item['Condition'] ?? item['airesponse'] ?? item['Airesponse'] ?? 'Unknown').toString();
                              final severity = (item['severity'] ?? item['Severity'] ?? 'Moderate').toString();
                              final createdAt = (item['createdAt'] ?? item['CreatedAt'] ?? '').toString();
                              final config = _severityConfig(severity);

                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: config.border),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: config.background.withOpacity(0.6),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(config.icon, color: config.foreground),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              condition,
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Severity: $severity'),
                                      const SizedBox(height: 8),
                                      Text(
                                        symptoms,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (createdAt.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          createdAt,
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  _TriageConfig _severityConfig(String value) {
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'severe':
      case 'high':
      case 'urgent':
      case 'critical':
        return const _TriageConfig(
          background: Color(0xFFFFEBEE),
          border: Color(0xFFE57373),
          foreground: Color(0xFFC62828),
          icon: Icons.error_rounded,
          summary: 'High urgency. Seek prompt medical attention.',
          actionTitle: 'See a Doctor Immediately',
        );
      case 'moderate':
      case 'medium':
        return const _TriageConfig(
          background: Color(0xFFFFF3E0),
          border: Color(0xFFFFB74D),
          foreground: Color(0xFFEF6C00),
          icon: Icons.local_hospital_rounded,
          summary: 'Moderate urgency. An appointment is recommended.',
          actionTitle: 'Recommended Follow-Up',
        );
      case 'mild':
      case 'low':
      default:
        return const _TriageConfig(
          background: Color(0xFFE8F5E9),
          border: Color(0xFF81C784),
          foreground: Color(0xFF2E7D32),
          icon: Icons.health_and_safety_rounded,
          summary: 'Mild urgency. Home care and monitoring may help.',
          actionTitle: 'Home Care Guidance',
        );
    }
  }
}

class _TriageConfig {
  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;
  final String summary;
  final String actionTitle;

  const _TriageConfig({
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
    required this.summary,
    required this.actionTitle,
  });
}