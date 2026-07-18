import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class PrescriptionCard extends StatelessWidget {
  final String rawPrescription;

  const PrescriptionCard({super.key, required this.rawPrescription});

  @override
  Widget build(BuildContext context) {
    final parsed = _parsePrescription(rawPrescription);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                  bottom: BorderSide(color: AppTheme.primary.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: AppTheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Medical Prescription',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (parsed['diagnosis'] != null) ...[
                  _buildSectionHeader(Icons.medical_information, 'Diagnosis'),
                  const SizedBox(height: 8),
                  Text(
                    parsed['diagnosis']!,
                    style: const TextStyle(
                        fontSize: 14, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                ],
                if ((parsed['medications'] as List).isNotEmpty) ...[
                  _buildSectionHeader(Icons.medication, 'Medications'),
                  const SizedBox(height: 12),
                  ...((parsed['medications'] as List<String>)
                      .map((med) => _buildMedicationItem(med))),
                  const SizedBox(height: 16),
                ],
                if (parsed['notes'] != null &&
                    (parsed['notes'] as String).isNotEmpty) ...[
                  if ((parsed['medications'] as List).isNotEmpty)
                    const Divider(),
                  const SizedBox(height: 16),
                  _buildSectionHeader(Icons.note_alt, 'Additional Notes'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppTheme.warning.withOpacity(0.2)),
                    ),
                    child: Text(
                      parsed['notes']!,
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Icon(Icons.circle, size: 8, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _parsePrescription(String text) {
    final result = <String, dynamic>{
      'diagnosis': null,
      'medications': <String>[],
      'notes': null,
    };

    try {
      final lines = text.split('\n');
      String currentSection = 'diagnosis';
      String currentNotes = '';
      String currentDiagnosis = '';

      for (var line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        if (trimmed.startsWith('Diagnosis:')) {
          currentSection = 'diagnosis';
          currentDiagnosis = trimmed.substring('Diagnosis:'.length).trim();
        } else if (trimmed.startsWith('Medications:')) {
          currentSection = 'medications';
        } else if (trimmed.startsWith('Notes:')) {
          currentSection = 'notes';
          currentNotes = trimmed.substring('Notes:'.length).trim();
        } else if (currentSection == 'medications' && trimmed.startsWith('-')) {
          result['medications'].add(trimmed.substring(1).trim());
        } else if (currentSection == 'diagnosis') {
          if (currentDiagnosis.isNotEmpty) currentDiagnosis += ' ';
          currentDiagnosis += trimmed;
        } else if (currentSection == 'notes') {
          if (currentNotes.isNotEmpty) currentNotes += '\n';
          currentNotes += trimmed;
        }
      }

      if (currentDiagnosis.isNotEmpty) result['diagnosis'] = currentDiagnosis;
      if (currentNotes.isNotEmpty) result['notes'] = currentNotes;
    } catch (e) {
      // Fallback
      result['notes'] = text;
    }

    return result;
  }
}
