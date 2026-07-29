import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'ai_symptom_result_controller.dart';
import 'package:medi_ai/config/app_theme.dart';

class AiSymptomResultScreen extends GetView<AiSymptomResultController> {
  const AiSymptomResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visit Summary'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTriageBadge(),
              const SizedBox(height: 16),
              
              _buildConditionCard(),
              const SizedBox(height: 16),

              if (controller.summary.isNotEmpty) ...[
                _buildSummaryCard(),
                const SizedBox(height: 16),
              ],

              if (controller.recommendations.isNotEmpty)
                _buildChecklistCard('Recommendations', controller.recommendations, Icons.check_circle_outline, Colors.blue),
              const SizedBox(height: 16),

              if (controller.homeCareGuidance.isNotEmpty)
                _buildChecklistCard('Home Care Guidance', controller.homeCareGuidance, Icons.home_repair_service_outlined, Colors.teal),
              const SizedBox(height: 16),

              if (controller.transcript.isNotEmpty) ...[
                _buildTranscriptCard(),
                const SizedBox(height: 16),
              ],

              if (controller.whenToSeekCare.isNotEmpty)
                _buildWhenToSeekCare(),
              const SizedBox(height: 24),

              // Disclaimer
              Text(
                'Disclaimer: This tool provides general guidance, not a definitive medical diagnosis. If symptoms worsen, seek professional medical attention.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.offAllNamed('/symptom-analyzer'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('New Analysis'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => controller.bookAppointment(),
                      icon: const Icon(Icons.calendar_month, size: 20),
                      label: const Text('Book Doctor'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTriageBadge() {
    Color badgeColor;
    String label;
    IconData icon;

    switch (controller.triageTier.toLowerCase()) {
      case 'seek_care_urgently':
        badgeColor = Colors.red;
        label = 'Seek Care Urgently';
        icon = Icons.warning_rounded;
        break;
      case 'see_a_doctor_soon':
        badgeColor = Colors.orange;
        label = 'See a Doctor Soon';
        icon = Icons.access_time_filled;
        break;
      case 'self_care':
      default:
        badgeColor = Colors.green;
        label = 'Self Care';
        icon = Icons.health_and_safety;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: badgeColor, size: 28),
          const SizedBox(width: 12),
          Text(
            label.toUpperCase(),
            style: TextStyle(color: badgeColor, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('POSSIBLE CONDITION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text(
              controller.possibleCondition,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('Preliminary analysis, not a diagnosis (${controller.confidenceLevel} confidence).',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistCard(String title, List<String> items, IconData icon, MaterialColor themeColor) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: themeColor.shade600),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: themeColor.shade400, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(item, style: const TextStyle(fontSize: 15, height: 1.4))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildWhenToSeekCare() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notification_important, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text('When to Seek Immediate Care', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            controller.whenToSeekCare,
            style: TextStyle(fontSize: 15, color: Colors.red.shade900, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notes, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                const Text('Interview Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              controller.summary,
              style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(Get.context!).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppTheme.primary,
          collapsedIconColor: Colors.grey.shade600,
          title: Row(
            children: [
              Icon(Icons.chat_bubble_outline, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              const Text('Full Interview Transcript', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                children: controller.transcript.map((turn) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (turn['question']!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12).copyWith(bottomLeft: const Radius.circular(0)),
                            ),
                            child: Text(
                              turn['question']!,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        const SizedBox(height: 8),
                        if (turn['answer']!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12).copyWith(bottomRight: const Radius.circular(0)),
                            ),
                            child: Text(
                              turn['answer']!,
                              textAlign: TextAlign.right,
                              style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w500),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
