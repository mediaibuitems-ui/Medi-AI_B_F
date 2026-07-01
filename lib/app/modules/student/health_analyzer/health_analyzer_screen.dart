import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'health_analyzer_controller.dart';
import 'package:medi_ai/app/routes/app_routes.dart';

class HealthAnalyzerScreen extends StatelessWidget {
  const HealthAnalyzerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HealthAnalyzerController());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Health Analyzer'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text('Analyzing symptoms...', style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  );
                }

                if (controller.assessment.value == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'Describe how you are feeling below, and our AI will provide a preliminary triage and home care plan.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  );
                }

                final data = controller.assessment.value!;
                Color triageColor;
                switch (data.triageLevel.toUpperCase()) {
                  case 'EMERGENCY': triageColor = Colors.red; break;
                  case 'URGENT': triageColor = Colors.orange; break;
                  case 'ROUTINE': triageColor = Colors.blue; break;
                  default: triageColor = Colors.green; break;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: triageColor, size: 28),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      data.triageLevel.toUpperCase(),
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        color: triageColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Text('Clinical Analysis', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(data.analysis, style: theme.textTheme.bodyMedium),
                              
                              if (data.suggestedOtcMedicine != null && data.suggestedOtcMedicine!.isNotEmpty && data.suggestedOtcMedicine!.toLowerCase() != 'none') ...[
                                const SizedBox(height: 16),
                                Text('Suggested OTC Relief', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(data.suggestedOtcMedicine!, style: theme.textTheme.bodyMedium),
                              ],

                              if (data.homeCareProcedure.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text('Home Care Plan', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: data.homeCareProcedure.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.check_circle_outline, size: 20, color: Colors.green),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(data.homeCareProcedure[index])),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (data.doctorRecommendation != null && data.doctorRecommendation!.isNotEmpty && data.doctorRecommendation!.toLowerCase() != 'none') ...[
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                          onPressed: () => Get.toNamed(AppRoutes.bookAppointment),
                          icon: const Icon(Icons.calendar_today),
                          label: Text('Book ${data.doctorRecommendation} Now', style: const TextStyle(fontSize: 16)),
                        ),
                      ]
                    ],
                  ),
                );
              }),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.symptomController,
                      decoration: InputDecoration(
                        hintText: 'e.g., I have a severe headache and fever...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      controller.analyzeSymptoms();
                    },
                    child: const Icon(Icons.send),
                    elevation: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
