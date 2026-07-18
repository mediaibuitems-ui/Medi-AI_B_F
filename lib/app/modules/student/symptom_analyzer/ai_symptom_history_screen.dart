import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../config/app_theme.dart';
import 'ai_symptom_history_controller.dart';

class AiSymptomHistoryScreen extends GetView<AiSymptomHistoryController> {
  const AiSymptomHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  controller.error.value,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.loadHistory,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (controller.history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No analysis history yet.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadHistory,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.history.length,
            itemBuilder: (context, index) {
              final item = controller.history[index];
              final dateStr = (item['createdAt'] ?? item['CreatedAt']).toString();
              DateTime? date;
              try {
                date = DateTime.parse(dateStr).toLocal();
              } catch (_) {}

              final possibleCondition = (item['possibleCondition'] ?? item['PossibleCondition'] ?? 'Unknown').toString();
              final confidence = (item['confidenceLevel'] ?? item['ConfidenceLevel'] ?? 'N/A').toString();
              final severity = (item['calculatedSeverity'] ?? item['CalculatedSeverity'] ?? 'Unknown').toString();
              final selectedSymptoms = (item['selectedSymptoms'] ?? item['SelectedSymptoms'] ?? '').toString();

              Color severityColor = Colors.grey;
              if (severity.toLowerCase().contains('high') || severity.toLowerCase().contains('severe')) {
                severityColor = Colors.red;
              } else if (severity.toLowerCase().contains('moderate')) {
                severityColor = Colors.orange;
              } else if (severity.toLowerCase().contains('low') || severity.toLowerCase().contains('mild')) {
                severityColor = Colors.green;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () => controller.viewResult(item),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                possibleCondition,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (date != null)
                              Text(
                                DateFormat('MMM d, yyyy • h:mm a').format(date),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: severityColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                severity,
                                style: TextStyle(
                                  color: severityColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$confidence Confidence',
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Symptoms: $selectedSymptoms',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
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
