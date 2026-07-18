import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'register_email_controller.dart';
import '../../../../config/app_theme.dart';
import '../../../routes/app_routes.dart';

/// Registration page for creating a new student, faculty, doctor, or admin account.
class RegisterEmailScreen extends GetView<RegisterEmailController> {
  RegisterEmailScreen({super.key});

  // Create a unique form key per screen instance
  final _formKey = GlobalKey<FormState>(); // Unique form key for validation.

  @override
  Widget build(BuildContext context) {
    // Pass the local form key to the controller
    Get.find<RegisterEmailController>().formKey = _formKey;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Logo section at the top of the page.
                Center(
                  child: Image.asset(
                    'assets/images/logos/buitems-logo-png_seeklogo-273407.png',
                    height: 100,
                    width: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.account_balance,
                        size: 80,
                        color: AppTheme.primary,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Main heading.
                Text(
                  'Create Account',
                  style: AppTheme.h1.copyWith(color: AppTheme.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Short subtitle explaining the page purpose.
                Text(
                  'Join our healthcare platform today',
                  style: AppTheme.bodyMedium.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Role selection section.
                _buildRoleSelection(),
                const SizedBox(height: 24),

                // First and last name fields are placed side by side.
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: controller.firstNameController,
                        label: 'First Name',
                        prefixIcon: Icons.person_outline,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'This field is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: controller.lastNameController,
                        label: 'Last Name',
                        prefixIcon: Icons.person_outline,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'This field is required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Email field.
                _buildTextField(
                  controller: controller.emailController,
                  label: 'Email Address',
                  hint: 'your.email@example.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  maxLength: 50,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Email is required';
                    }
                    if (!GetUtils.isEmail(value!)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone field.
                _buildTextField(
                  controller: controller.phoneController,
                  label: 'Mobile Number',
                  hint: '+92 300 1234567',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Mobile number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date of birth picker.
                _buildDateOfBirthField(),
                const SizedBox(height: 16),

                // Gender chips.
                _buildGenderSelection(),
                const SizedBox(height: 16),

                // Optional address field.
                _buildTextField(
                  controller: controller.addressController,
                  label: 'Address (Optional)',
                  hint: 'Enter your residential address',
                  prefixIcon: Icons.home_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Department dropdown is shown for student and faculty accounts.
                Obx(() {
                  if (controller.selectedRole.value == 'Student' ||
                      controller.selectedRole.value == 'Faculty') {
                    return Column(
                      children: [
                        _buildDepartmentSelection(),
                        const SizedBox(height: 16),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),

                // Doctor-specific profile fields.
                Obx(() {
                  if (controller.selectedRole.value == 'Doctor') {
                    return Column(
                      children: [
                        _buildTextField(
                          controller: controller.specializationController,
                          label: 'Specialization',
                          hint: 'e.g., Cardiology, Orthopedics',
                          prefixIcon: Icons.medical_services_outlined,
                          validator: (value) {
                            if (controller.selectedRole.value == 'Doctor' &&
                                (value?.trim().isEmpty ?? true)) {
                              return 'Specialization is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: controller.licenseNumberController,
                          label: 'License Number',
                          hint: 'PMC-XXXXX',
                          prefixIcon: Icons.badge_outlined,
                          validator: (value) {
                            if (controller.selectedRole.value == 'Doctor' &&
                                (value?.trim().isEmpty ?? true)) {
                              return 'License number is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: controller.qualificationController,
                          label: 'Qualification',
                          hint: 'e.g. MBBS, FCPS',
                          prefixIcon: Icons.school_outlined,
                          validator: (value) {
                            if (controller.selectedRole.value == 'Doctor' &&
                                (value?.trim().isEmpty ?? true)) {
                              return 'Qualification is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: controller.experienceController,
                                label: 'Years of Experience',
                                prefixIcon: Icons.timeline,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: controller.roomNumberController,
                          label: 'Room Number (Optional)',
                          prefixIcon: Icons.meeting_room_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: controller.bioController,
                          label: 'Bio (Optional)',
                          hint: 'Brief professional bio',
                          prefixIcon: Icons.description_outlined,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),

                // CMS ID field for student and faculty accounts.
                Obx(() {
                  if (controller.selectedRole.value == 'Student' ||
                      controller.selectedRole.value == 'Faculty') {
                    return Column(
                      children: [
                        _buildTextField(
                          controller: controller.cmsIdController,
                          label: 'Registration/CMS ID',
                          prefixIcon: Icons.badge_outlined,
                          validator: (value) {
                            if (controller.selectedRole.value != 'Doctor' &&
                                (value?.trim().isEmpty ?? true)) {
                              return 'Registration/CMS ID is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),

                // Password field.
                Obx(() => _buildTextField(
                      controller: controller.passwordController,
                      label: 'Password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: !controller.showPassword.value,
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.showPassword.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: controller.togglePasswordVisibility,
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Password is required';
                        }
                        if (value!.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    )),
                const SizedBox(height: 16),

                // Confirm-password field.
                Obx(() => _buildTextField(
                      controller: controller.confirmPasswordController,
                      label: 'Confirm Password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: !controller.showConfirmPassword.value,
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.showConfirmPassword.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: controller.toggleConfirmPasswordVisibility,
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please confirm your password';
                        }
                        if (value != controller.passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    )),
                const SizedBox(height: 32),

                // Submit button for account creation.
                Obx(() => ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.handleSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Create Account',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    )),
                const SizedBox(height: 24),

                // Link back to the login screen.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style:
                          AppTheme.bodyMedium.copyWith(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () => Get.offNamed(AppRoutes.login),
                      child: Text(
                        'Login',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the role selection chips.
  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am a',
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildRoleChip('Student', Icons.school),
            _buildRoleChip('Faculty', Icons.work_outline),
            _buildRoleChip('Doctor', Icons.medical_services_outlined),
            _buildRoleChip('Admin', Icons.admin_panel_settings_outlined),
          ],
        ),
      ],
    );
  }

  /// Builds one selectable role chip.
  Widget _buildRoleChip(String role, IconData icon) {
    return Obx(() {
      final isSelected = controller.selectedRole.value == role;
      return FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18, color: isSelected ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 8),
            Text(_translateRole(role),
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          controller.selectRole(selected ? role : '');
        },
        backgroundColor: Colors.white,
        selectedColor: AppTheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? AppTheme.primary : Colors.grey[300]!,
          ),
        ),
      );
    });
  }

  /// Builds the department dropdown for student and faculty accounts.
  Widget _buildDepartmentSelection() {
    final departments = [
      'Computer Science',
      'Software Engineering',
      'Electrical Engineering',
      'Telecommunication Engineering',
      'Electronic Engineering',
      'Information Technology',
      'Computer Engineering',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Department',
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: controller.selectedDepartment.value.isEmpty
                      ? null
                      : controller.selectedDepartment.value,
                  hint: Text(
                    'Select Department',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, color: Colors.grey[500]),
                  items: departments.map((dept) {
                    return DropdownMenuItem(
                      value: dept,
                      child: Text(
                        _translateDepartment(dept),
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectDepartment(value);
                    }
                  },
                ),
              ),
            )),
      ],
    );
  }

  /// Builds the gender selector.
  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildGenderChip('Male', Icons.male),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGenderChip('Female', Icons.female),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds one gender chip.
  Widget _buildGenderChip(String gender, IconData icon) {
    return Obx(() {
      final isSelected = controller.selectedGender.value == gender;
      return FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16, color: isSelected ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(_translateGender(gender),
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          controller.selectGender(selected ? gender : '');
        },
        backgroundColor: Colors.white,
        selectedColor: AppTheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? AppTheme.primary : Colors.grey[300]!,
          ),
        ),
      );
    });
  }

  /// Builds the date-of-birth picker card.
  Widget _buildDateOfBirthField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date of Birth',
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() => InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: Get.context!,
                  initialDate:
                      DateTime.now().subtract(const Duration(days: 365 * 18)),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.light().copyWith(
                        primaryColor: AppTheme.primary,
                        colorScheme:
                            const ColorScheme.light(primary: AppTheme.primary),
                      ),
                      child: child!,
                    );
                  },
                );
                if (date != null) {
                  controller.setDateOfBirth(date);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppTheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        controller.dateOfBirth.value.isEmpty
                            ? 'Select Date of Birth'
                            : controller.dateOfBirth.value,
                        style: TextStyle(
                          color: controller.dateOfBirth.value.isEmpty
                              ? Colors.grey[600]
                              : AppTheme.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  /// Reusable labeled text field used throughout the registration form.
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          maxLines: maxLines,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: Icon(prefixIcon, color: Colors.grey[500]),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  /// Converts a role label into the shorter display key used in the UI.
  String _translateRole(String role) {
    switch (role) {
      case 'Student':
        return 'Student';
      case 'Faculty':
        return 'Faculty';
      case 'Doctor':
        return 'Doctor';
      case 'Admin':
        return 'Admin';
      default:
        return role;
    }
  }

  /// Converts a gender label into the shorter display key used in the UI.
  String _translateGender(String gender) {
    switch (gender) {
      case 'Male':
        return 'Male';
      case 'Female':
        return 'Female';
      default:
        return gender;
    }
  }

  /// Converts a department name into the shorter display key used in the UI.
  String _translateDepartment(String department) {
    switch (department) {
      case 'Computer Science':
        return 'Computer Science';
      case 'Software Engineering':
        return 'Software Engineering';
      case 'Electrical Engineering':
        return 'Electrical Engineering';
      case 'Telecommunication Engineering':
        return 'Telecommunication Engineering';
      case 'Electronic Engineering':
        return 'Electronic Engineering';
      case 'Information Technology':
        return 'Information Technology';
      case 'Computer Engineering':
        return 'Computer Engineering';
      default:
        return department;
    }
  }
}
