import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../config/app_theme.dart';
import 'doctor_profile_controller.dart';

export 'doctor_profile_binding.dart';

class DoctorProfileScreen extends GetView<DoctorProfileController> {
  const DoctorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = controller.authService.currentUser.value;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.surface,
        actions: [
          Obx(() => controller.isEditMode.value
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: controller.toggleEditMode,
                )),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Picture
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: AppTheme.primary,
                child: const Icon(Icons.medical_information,
                    size: 60, color: AppTheme.surface),
              ),
            ),
            const SizedBox(height: 24),

            // Personal Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal & Doctor Information',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: controller.nameController,
                        enabled: controller.isEditMode.value,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: user?.email ?? '',
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: controller.phoneController,
                        enabled: controller.isEditMode.value,
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: controller.specializationController,
                        decoration: const InputDecoration(
                          labelText: 'Specialization',
                          prefixIcon: Icon(Icons.medical_services_outlined),
                        ),
                        enabled: controller.isEditMode.value,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: controller.licenseNumberController,
                        decoration: const InputDecoration(
                          labelText: 'License Number',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        enabled: controller.isEditMode.value,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your license number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: controller.roomController,
                        decoration: const InputDecoration(
                          labelText: 'Room number',
                          prefixIcon: Icon(Icons.meeting_room_outlined),
                        ),
                        enabled: controller.isEditMode.value,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: controller.bioController,
                        decoration: const InputDecoration(
                          labelText: 'Bio',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        enabled: controller.isEditMode.value,
                        maxLines: 3,
                      ),
                      if (controller.hasTempLicense) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'You cannot mark yourself as available until you update your temporary license number.',
                                  style: TextStyle(
                                    color: AppTheme.warning.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Available for appointments'),
                        value: controller.isAvailable.value,
                        onChanged: (controller.isEditMode.value && !controller.hasTempLicense)
                            ? (val) => controller.isAvailable.value = val
                            : null,
                        secondary: const Icon(Icons.check_circle_outline),
                      ),
                      if (controller.isEditMode.value) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: controller.toggleEditMode,
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: controller.saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Save changes'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Security
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Security',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: controller.togglePasswordSection,
                          icon: Icon(
                            controller.showPasswordSection.value
                                ? Icons.expand_less
                                : Icons.expand_more,
                          ),
                          label: const Text('Change password'),
                        ),
                      ],
                    ),
                    if (controller.showPasswordSection.value) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller.currentPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Current password',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller.newPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'New password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller.confirmPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Confirm new password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: controller.changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Update password'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      }),
    );
  }
}
