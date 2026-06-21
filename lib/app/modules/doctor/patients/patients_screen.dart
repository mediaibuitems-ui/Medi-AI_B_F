import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../../../../config/app_theme.dart';
import 'patients_controller.dart';

export 'patients_binding.dart';

class PatientsScreen extends GetView<PatientsController> {
  const PatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Patients'),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.surface,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.patients.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline,
                    size: 64, color: AppTheme.textSecondary.withOpacity(0.18)),
                const SizedBox(height: 16),
                Text(
                  'No patients found.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          );
        }

        final patients = controller.filteredPatients;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                onChanged: controller.onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search by name or CMS number',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.border.withOpacity(0.08)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.4)),
                  ),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: patients.isEmpty
                  ? Center(
                      child: Text(
                        'No matching patient found.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: patients.length,
                      itemBuilder: (context, index) {
                        final patient = patients[index];
                        final name =
                            (patient['fullName'] ?? patient['FullName'] ?? 'Unknown')
                                .toString();
                        final email =
                            (patient['email'] ?? patient['Email'] ?? '').toString();
                        final phone = (patient['phoneNumber'] ??
                                patient['PhoneNumber'] ??
                                '')
                            .toString();
                        final image =
                            patient['profileImageUrl'] ?? patient['ProfileImageUrl'];
                        final dob = (patient['dateOfBirth'] ??
                                patient['DateOfBirth'] ??
                                '')
                            .toString()
                            .split('T')[0];
                        final gender =
                            (patient['gender'] ?? patient['Gender'] ?? '').toString();
                        final cmsNumber = (patient['registrationNumber'] ??
                                patient['RegistrationNumber'] ??
                                patient['cmsNumber'] ??
                                patient['CmsNumber'] ??
                                '')
                            .toString();
                        final hasImage =
                            image != null && image.toString().trim().isNotEmpty;
                        final initial =
                            name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primary.withOpacity(0.1),
                              backgroundImage:
                                  hasImage ? NetworkImage(image.toString()) : null,
                              child: hasImage
                                  ? null
                                  : Text(
                                      initial,
                                      style:
                                          const TextStyle(color: AppTheme.primary),
                                    ),
                            ),
                            title: Text(name,
                                style:
                                    const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              cmsNumber.isNotEmpty
                                  ? 'CMS: $cmsNumber'
                                  : (email.isNotEmpty ? email : 'No email'),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Column(
                                  children: [
                                    if (cmsNumber.isNotEmpty)
                                      _buildInfoRow(Icons.badge, 'CMS', cmsNumber),
                                    if (phone.isNotEmpty)
                                      _buildInfoRow(Icons.phone, 'Phone', phone),
                                    if (email.isNotEmpty)
                                      _buildInfoRow(Icons.email, 'Email', email),
                                    if (gender.isNotEmpty)
                                      _buildInfoRow(Icons.person, 'Gender', gender),
                                    if (dob.isNotEmpty)
                                      _buildInfoRow(Icons.cake, 'Date of Birth', dob),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Get.toNamed(
                                            AppRoutes.patientDetail,
                                            arguments: patient,
                                          );
                                        },
                                        icon: const Icon(Icons.visibility),
                                        label: const Text('View Details'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primary,
                                          foregroundColor: AppTheme.surface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: AppTheme.textSecondary)),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

