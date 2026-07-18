import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/auth_service.dart';
import '../../../services/storage_service.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/app_feedback.dart';

/// Handles login form state and authentication actions.
class LoginController extends GetxController {
  // AuthService provides the actual API login call and current user state.
  final _authService = Get.find<AuthService>();
  final _storageService = Get.find<StorageService>();

  // Form key used to validate the login fields.
  GlobalKey<FormState>? formKey;

  // Controllers
  // Email input controller.
  late TextEditingController emailController;
  // Password input controller.
  late TextEditingController passwordController;

  // Observables
  // Controls whether the password is visible.
  final RxBool showPassword = false.obs;
  // Tracks whether the login request is currently running.
  final RxBool isLoading = false.obs;
  // Stores the remember-me checkbox state.
  final RxBool rememberMe = false.obs;

  @override

  /// Creates the text controllers and loads saved credentials if needed.
  void onInit() {
    super.onInit();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    _loadSavedCredentials();
  }

  @override

  /// Cleans up the controller when the screen is removed.
  void onClose() {
    // Delay disposal to prevent 'used after dispose' crashes during route transitions
    // when GetX synchronously closes controllers.
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        emailController.dispose();
        passwordController.dispose();
      } catch (_) {}
    });
    super.onClose();
  }

  /// Loads any saved login data for the remember-me feature.
  Future<void> _loadSavedCredentials() async {
    final savedEmail = _storageService.getRememberMeEmail();
    if (savedEmail != null && savedEmail.isNotEmpty) {
      emailController.text = savedEmail;
      rememberMe.value = true;
    }
  }

  /// Toggles password visibility in the login field.
  void togglePasswordVisibility() {
    showPassword.value = !showPassword.value;
  }

  /// Toggles the remember-me checkbox.
  void toggleRememberMe() {
    rememberMe.value = !rememberMe.value;
  }

  /// Validates the form and sends the login request.
  Future<void> handleLogin() async {
    // Do not continue if the form is invalid or not yet attached.
    if (formKey == null ||
        formKey!.currentState == null ||
        !formKey!.currentState!.validate()) return;

    // Show a loading state while the backend request runs.
    isLoading.value = true;

    try {
      // Send email and password to the auth service.
      final response = await _authService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (response.success && response.data != null) {
        if (rememberMe.value) {
          await _storageService
              .saveRememberMeEmail(emailController.text.trim());
        } else {
          await _storageService.removeRememberMeEmail();
        }

        AppFeedback.success(
            'Welcome back', 'Login successful. Loading your dashboard...');

        // Route the user to the correct dashboard based on their role.
        final user = _authService.currentUser.value;
        if (user != null) {
          if (user.isStudent) {
            Get.offAllNamed(AppRoutes.studentDashboard);
          } else if (user.isFaculty) {
            Get.offAllNamed(AppRoutes.facultyDashboard);
          } else if (user.isDoctor) {
            Get.offAllNamed(AppRoutes.doctorDashboard);
          } else if (user.isAdmin) {
            Get.offAllNamed(AppRoutes.adminDashboard);
          } else {
            // Default to student dashboard
            Get.offAllNamed(AppRoutes.studentDashboard);
          }
        }
      } else {
        // If the backend rejects the login, show the returned error.
        AppFeedback.error(
          'Login failed',
          response.message.isNotEmpty
              ? response.message
              : 'Invalid email or password',
        );
      }
    } catch (e) {
      // Show unexpected runtime or network errors.
      AppFeedback.error('Login error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Opens the registration screen.
  void goToRegister() {
    Get.toNamed(AppRoutes.registerEmail);
  }

  /// Opens the forgot-password screen.
  void forgotPassword() {
    Get.toNamed(AppRoutes.forgotPassword);
  }
}
