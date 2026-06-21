import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/auth_service.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/app_feedback.dart';

class ForgotPasswordController extends GetxController {
  final _authService = Get.find<AuthService>();

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final cmsController = TextEditingController();

  final RxBool isLoading = false.obs;

  @override
  void onClose() {
    emailController.dispose();
    phoneController.dispose();
    cmsController.dispose();
    super.onClose();
  }

  Future<void> verifyAndReset() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;

    try {
      final response = await _authService.forgotPassword(
        email: emailController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        registrationNumber: cmsController.text.trim(),
      );

      isLoading.value = false;

      if (response.success) {
        AppFeedback.success(
          'Success',
          response.message ?? 'OTP sent to your email.',
        );

        // Navigate to OTP Verification Screen
        Get.toNamed(
          AppRoutes.otpVerification,
          arguments: {
            'email': emailController.text.trim(),
            'isPasswordReset': true,
          },
        );
      } else {
        AppFeedback.error(
          'Verification Failed',
          response.message,
        );
      }
    } catch (e) {
      isLoading.value = false;
      AppFeedback.error(
        'Error',
        'Something went wrong. Please try again.',
      );
    }
  }
}
