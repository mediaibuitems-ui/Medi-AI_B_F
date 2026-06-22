import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import '../../../services/auth_service.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/app_feedback.dart';

/// Handles registration form state and submits the new-account request.
class RegisterEmailController extends GetxController {
  // AuthService performs the registration API call.
  final _authService = Get.find<AuthService>();

  // Assigned by the screen so validation can run on the current form instance.
  late GlobalKey<FormState> formKey;

  final _logger = Logger();

  // Controllers
  // First name input.
  final firstNameController = TextEditingController();
  // Last name input.
  final lastNameController = TextEditingController();
  // Email input.
  final emailController = TextEditingController();
  // Password input.
  final passwordController = TextEditingController();
  // Confirm password input.
  final confirmPasswordController = TextEditingController();
  // Phone number input.
  final phoneController = TextEditingController();
  // CMS/registration ID input.
  final cmsIdController = TextEditingController();
  // Alias kept for compatibility with older registration logic.
  final registrationNumberController = TextEditingController();
  // Address input.
  final addressController = TextEditingController();
  // Doctor specialization input.
  final specializationController = TextEditingController();
  // Doctor license number input.
  final licenseNumberController = TextEditingController();
  // Doctor qualification input.
  final qualificationController = TextEditingController();
  // Doctor experience input.
  final experienceController = TextEditingController();
  // Doctor room number input.
  final roomNumberController = TextEditingController();
  // Doctor bio input.
  final bioController = TextEditingController();

  // Observables
  // Controls password visibility.
  final RxBool showPassword = false.obs;
  // Controls confirm-password visibility.
  final RxBool showConfirmPassword = false.obs;
  // Shows loading state while the request runs.
  final RxBool isLoading = false.obs;
  // Stores the selected account role.
  final RxString selectedRole = ''.obs;
  // Stores the selected department for student/faculty accounts.
  final RxString selectedDepartment = ''.obs;
  // Stores the selected gender.
  final RxString selectedGender = ''.obs;
  // Stores the selected date of birth in display format.
  final RxString dateOfBirth = ''.obs;

  @override

  /// Releases controller resources when the screen closes.
  void onClose() {
    // Safely dispose controllers. Wrap each dispose in try/catch to avoid
    // navigation-time race conditions where the widget tree may already
    // be tearing down and a controller gets accessed after dispose.
    try {
      firstNameController.dispose();
    } catch (_) {}
    try {
      lastNameController.dispose();
    } catch (_) {}
    try {
      emailController.dispose();
    } catch (_) {}
    try {
      passwordController.dispose();
    } catch (_) {}
    try {
      confirmPasswordController.dispose();
    } catch (_) {}
    try {
      cmsIdController.dispose();
    } catch (_) {}
    try {
      phoneController.dispose();
    } catch (_) {}
    try {
      addressController.dispose();
    } catch (_) {}
    try {
      specializationController.dispose();
    } catch (_) {}
    try {
      licenseNumberController.dispose();
    } catch (_) {}
    try {
      qualificationController.dispose();
    } catch (_) {}
    try {
      experienceController.dispose();
    } catch (_) {}
    try {
      roomNumberController.dispose();
    } catch (_) {}
    try {
      bioController.dispose();
    } catch (_) {}

    super.onClose();
  }

  /// Toggles the password field visibility.
  void togglePasswordVisibility() {
    showPassword.value = !showPassword.value;
  }

  /// Toggles the confirm-password field visibility.
  void toggleConfirmPasswordVisibility() {
    showConfirmPassword.value = !showConfirmPassword.value;
  }

  /// Stores the selected role.
  void selectRole(String role) {
    selectedRole.value = role;
  }

  /// Stores the selected department.
  void selectDepartment(String dept) {
    selectedDepartment.value = dept;
  }

  /// Stores the selected gender.
  void selectGender(String gender) {
    selectedGender.value = gender;
  }

  /// Formats the picked date for display in the UI.
  void setDateOfBirth(DateTime date) {
    dateOfBirth.value = DateFormat('dd/MM/yyyy').format(date);
  }

  /// Converts the display date format into the backend-friendly format.
  String? _convertDateFormat(String date) {
    try {
      // Convert from dd/MM/yyyy to yyyy-MM-dd.
      final parsedDate = DateFormat('dd/MM/yyyy').parse(date);
      return DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (e) {
      // Return null if the date cannot be parsed.
      _logger.w('Error converting date: $e');
      return null;
    }
  }

  /// Validates the registration form and sends the sign-up request.
  Future<void> handleSignup() async {
    _logger.d('Signup button clicked');
    _logger.d('Form validation: ${formKey.currentState?.validate()}');

    // Stop immediately if the form validator fails.
    if (!formKey.currentState!.validate()) {
      _logger.w('Form validation failed - check required fields');
      AppFeedback.error('Validation error', 'Please fill in all required fields');
      return;
    }

    // Role is mandatory for the registration flow.
    if (selectedRole.value.isEmpty) {
      _logger.w('Role not selected');
      AppFeedback.error('Required', 'Please select a role');
      return;
    }

    // Email Domain Validation removed to allow any email domain.

    // Gender is required by the backend.
    if (selectedGender.value.isEmpty) {
      _logger.w('Gender not selected');
      AppFeedback.error('Required', 'Please select a gender');
      return;
    }

    // DOB is required so the backend can store a valid profile.
    if (dateOfBirth.value.isEmpty) {
      _logger.w('Date of birth not selected');
      AppFeedback.error('Required', 'Please select a date of birth');
      return;
    }

    // Student and faculty accounts must also choose a department.
    if ((selectedRole.value == 'Student' || selectedRole.value == 'Faculty') &&
        selectedDepartment.value.isEmpty) {
      _logger.w('Department not selected for ${selectedRole.value}');
      AppFeedback.error('Required', 'Please select a department');
      return;
    }

    // Doctor accounts require extra profile fields.
    if (selectedRole.value == 'Doctor') {
      if (specializationController.text.trim().isEmpty ||
          licenseNumberController.text.trim().isEmpty ||
          qualificationController.text.trim().isEmpty) {
        AppFeedback.error('Required', 'Please fill in all doctor-specific fields');
        return;
      }
    }

    _logger.d('All validations passed, proceeding with registration...');
    // Switch the UI into a loading state.
    isLoading.value = true;

    try {
      // Log the registration payload summary.
      _logger.d('ðŸš€ Starting registration for: ${emailController.text.trim()}');
      _logger.d('Form data:\n'
          '  - Role: ${selectedRole.value}\n'
          '  - Department: ${selectedDepartment.value}\n'
          '  - CMS ID: ${cmsIdController.text.trim()}\n'
          '  - Gender: ${selectedGender.value}\n'
          '  - DOB: ${dateOfBirth.value}\n'
          '  - Phone: ${phoneController.text.trim()}\n'
          '  - Address: ${addressController.text.trim()}');

      final response = await _authService.register(
        email: emailController.text.trim(),
        password: passwordController.text,
        name:
            '${firstNameController.text.trim()} ${lastNameController.text.trim()}',
        role: selectedRole.value,
        department: selectedDepartment.value.isNotEmpty
            ? selectedDepartment.value
            : null,
        cmsId: cmsIdController.text.trim().isNotEmpty
            ? cmsIdController.text.trim()
            : null,
        phoneNumber: phoneController.text.trim().isNotEmpty
            ? phoneController.text.trim()
            : null,
        dateOfBirth: dateOfBirth.value.isNotEmpty
            ? _convertDateFormat(dateOfBirth.value)
            : null,
        gender: selectedGender.value.isNotEmpty ? selectedGender.value : null,
        address: addressController.text.trim().isNotEmpty
            ? addressController.text.trim()
            : null,
        specialization: specializationController.text.trim().isNotEmpty
            ? specializationController.text.trim()
            : null,
        licenseNumber: licenseNumberController.text.trim().isNotEmpty
            ? licenseNumberController.text.trim()
            : null,
        qualification: qualificationController.text.trim().isNotEmpty
            ? qualificationController.text.trim()
            : null,
        experience: int.tryParse(experienceController.text.trim()),
        roomNumber: roomNumberController.text.trim().isNotEmpty
            ? roomNumberController.text.trim()
            : null,
        bio: bioController.text.trim().isNotEmpty
            ? bioController.text.trim()
            : null,
      );

      _logger.d('Registration response - Success: ${response.success}, Message: ${response.message}');

      if (response.success) {
        // Capture a dev OTP if the backend returned one.
        String? devOtp;
        if (response.data != null && response.data is Map) {
          final data = response.data as Map<String, dynamic>;
          devOtp = data['otp']?.toString();
          if (devOtp != null) {
            _logger.i('DEV MODE - OTP received from backend: $devOtp');
          }
        }

        // Show a short success snackbar before redirecting to OTP verification.
        AppFeedback.success('Success', 'Registration successful. Please verify your email.');

        // Wait briefly so the user sees the success message.
        await Future.delayed(const Duration(milliseconds: 500));

        // Send the user to the OTP Verification screen after account creation.
        Get.offAllNamed(AppRoutes.otpVerification, arguments: {
          'email': emailController.text.trim(),
          'devOtp': devOtp,
        });

        _logger.d('Navigation command sent to OTP Verification screen');
      } else {
        // Display the backend error if registration fails.
        _logger.w('Registration failed: ${response.message}');
        AppFeedback.error('Error', response.message);
      }
    } catch (e) {
      // Catch and show unexpected registration errors.
      _logger.e('Registration exception', error: e);
      AppFeedback.error('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
