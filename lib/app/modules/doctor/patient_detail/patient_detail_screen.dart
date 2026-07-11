import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/medical_history.dart';
import '../../../services/doctor_service.dart';
import '../../../../config/app_theme.dart';

export 'patient_detail_binding.dart';

class PatientDetailScreen extends StatelessWidget {
  const PatientDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get patient data from arguments
    final args = Get.arguments is Map
        ? Map<String, dynamic>.from(Get.arguments as Map)
        : <String, dynamic>{};

    final patientName = (args['fullName'] ??
            args['FullName'] ??
            args['patientName'] ??
            'Patient')
        .toString();
    final patientId =
        (args['id'] ?? args['Id'] ?? args['patientId'] ?? 'N/A').toString();
    final patientIdInt = int.tryParse(patientId);
    final registrationNumber = (args['registrationNumber'] ??
            args['RegistrationNumber'] ??
            args['cmsNumber'] ??
            args['CmsNumber'] ??
            'N/A')
        .toString();
    final gender = (args['gender'] ?? args['Gender'] ?? 'N/A').toString();
    final phone =
        (args['phoneNumber'] ?? args['PhoneNumber'] ?? 'N/A').toString();
    final email = (args['email'] ?? args['Email'] ?? 'N/A').toString();
    final dobRaw = (args['dateOfBirth'] ?? args['DateOfBirth'] ?? '')
        .toString()
        .split('T')[0];
    final exactAge = _calculateExactAge(dobRaw);
    final dobDisplay = _formatDate(dobRaw);
    final lastVisitRaw =
        (args['lastVisit'] ?? args['LastVisit'] ?? '').toString().split('T')[0];
    final lastVisitDisplay =
        lastVisitRaw.isEmpty ? 'N/A' : _formatDate(lastVisitRaw);
    final department = (args['department'] ?? args['Department'] ?? 'Patient').toString();
    final subtitleInfo = [
      if (registrationNumber.isNotEmpty && registrationNumber != 'N/A') registrationNumber,
      if (department.isNotEmpty && department != 'Patient') department
    ].join(' • ');
    final displaySubtitle = subtitleInfo.isEmpty ? 'Active Patient' : subtitleInfo;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.surface),
          tooltip: 'Back',
          onPressed: () => Get.back(),
        ),
        title: const Text('Patient Details'),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPatientHeader(patientName, displaySubtitle),
            const SizedBox(height: 16),
            _buildInfoCard('Personal Information', [
              _buildInfoRow('CMS Number', registrationNumber),
              _buildInfoRow('Exact Age', exactAge),
              _buildInfoRow('Gender', gender.isEmpty ? 'N/A' : gender),
              _buildInfoRow('Date of Birth', dobDisplay),
              _buildInfoRow('Phone', phone.isEmpty ? 'N/A' : phone),
              _buildInfoRow('Email', email.isEmpty ? 'N/A' : email),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard('Medical History', [
              _buildInfoRow('Last Visit', lastVisitDisplay),
              _buildMedicalHistorySection(patientIdInt),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard('Emergency Contacts', [
              _buildEmergencyContactsSection(patientIdInt),
            ]),
            const SizedBox(height: 16),
            _buildActionButtons(args, patientIdInt, patientName),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalHistorySection(int? patientId) {
    if (patientId == null) {
      return _buildInfoRow('Records', 'Patient ID unavailable');
    }

    final doctorService = Get.find<DoctorService>();

    return FutureBuilder(
      future: doctorService.getPatientMedicalHistory(patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(minHeight: 3),
          );
        }

        if (!snapshot.hasData || !(snapshot.data?.success ?? false)) {
          final message = snapshot.data?.message ?? 'Unable to load records';
          return _buildInfoRow('Records', message);
        }

        final records = snapshot.data?.data ?? <MedicalHistory>[];
        if (records.isEmpty) {
          return _buildInfoRow('Records', 'No medical history found');
        }

        final allergies =
            records.where((r) => r.recordType == 'Allergy').length;
        final chronic =
            records.where((r) => r.recordType == 'ChronicCondition').length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Total Records', records.length.toString()),
            _buildInfoRow('Allergies', allergies.toString()),
            _buildInfoRow('Chronic Conditions', chronic.toString()),
            const SizedBox(height: 8),
            ...records.take(5).map((record) {
              final subtitle = [
                record.recordType,
                if ((record.diagnosisDate ?? '').isNotEmpty)
                  record.diagnosisDate!,
              ].join(' • ');

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppTheme.border.withOpacity(0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildEmergencyContactsSection(int? patientId) {
    if (patientId == null) {
      return _buildInfoRow('Contacts', 'Patient ID unavailable');
    }

    final doctorService = Get.find<DoctorService>();

    return FutureBuilder(
      future: doctorService.getPatientEmergencyContacts(patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(minHeight: 3),
          );
        }

        if (!snapshot.hasData || !(snapshot.data?.success ?? false)) {
          final message = snapshot.data?.message ?? 'Unable to load contacts';
          return _buildInfoRow('Contacts', message);
        }

        final contacts = snapshot.data?.data ?? <Map<String, dynamic>>[];
        if (contacts.isEmpty) {
          return _buildInfoRow('Contacts', 'No emergency contacts found');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...contacts.map((contact) {
              final name =
                  contact['contactName'] ?? contact['ContactName'] ?? 'Unknown';
              final relation =
                  contact['relationship'] ?? contact['Relationship'] ?? 'N/A';
              final phone =
                  contact['phoneNumber'] ?? contact['PhoneNumber'] ?? 'N/A';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppTheme.border.withOpacity(0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$name ($relation)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.phone,
                              size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  String _formatDate(String value) {
    if (value.trim().isEmpty) return 'N/A';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('dd MMM yyyy').format(parsed);
  }

  String _calculateExactAge(String dobValue) {
    if (dobValue.trim().isEmpty) return 'N/A';
    final dob = DateTime.tryParse(dobValue);
    if (dob == null) return 'N/A';

    final now = DateTime.now();
    var years = now.year - dob.year;
    var months = now.month - dob.month;
    var days = now.day - dob.day;

    if (days < 0) {
      final previousMonth = DateTime(now.year, now.month, 0);
      days += previousMonth.day;
      months -= 1;
    }
    if (months < 0) {
      months += 12;
      years -= 1;
    }

    if (years < 0) return 'N/A';
    return '$years years, $months months, $days days';
  }

  Widget _buildPatientHeader(String name, String id) {
    final trimmedName = name.trim();
    final initial = trimmedName.isNotEmpty
        ? trimmedName.substring(0, 1).toUpperCase()
        : 'P';
    return Container(
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
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.primary,
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppTheme.surface,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    id,
                    style:
                        TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Active Patient',
                      style: TextStyle(
                        color: AppTheme.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> args, int? patientIdInt, String patientName) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Get.snackbar(
                'Medical Records',
                'Viewing patient medical records is available in the Medical History section above.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppTheme.primary,
                colorText: AppTheme.surface,
              );
            },
            icon: const Icon(Icons.description),
            label: const Text('Medical Records'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              final appointmentId = args['appointmentId'] ?? args['AppointmentId'];
              if (appointmentId == null) {
                Get.snackbar(
                  'Action Unavailable',
                  'Prescriptions can only be written during an active appointment.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppTheme.error,
                  colorText: AppTheme.surface,
                );
                return;
              }
              Get.toNamed(
                '/write-prescription',
                arguments: {
                  'patientId': patientIdInt,
                  'appointmentId': appointmentId,
                  'patientName': patientName,
                },
              );
            },
            icon: const Icon(Icons.edit_note),
            label: const Text('Issue Prescription'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.surface,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}
