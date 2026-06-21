import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/auth_service.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/app_feedback.dart';

class OtpVerificationController extends GetxController {
  final _authService = Get.find<AuthService>();

  // OTP controllers (4 or 6 digits)
  final otp1Controller = TextEditingController();
  final otp2Controller = TextEditingController();
  final otp3Controller = TextEditingController();
  final otp4Controller = TextEditingController();
  final otp5Controller = TextEditingController();
  final otp6Controller = TextEditingController();

  // Focus nodes
  final otp1Focus = FocusNode();
  final otp2Focus = FocusNode();
  final otp3Focus = FocusNode();
  final otp4Focus = FocusNode();
  final otp5Focus = FocusNode();
  final otp6Focus = FocusNode();

  // Observables
  final RxBool isLoading = false.obs;
  final RxBool isResending = false.obs;
  final RxInt resendTimer = 60.obs;
  final RxString email = ''.obs;

  bool _isDisposed = false; // Track disposal state

  bool isPasswordReset = false;

  @override
  void onInit() {
    super.onInit();
    // Get email from arguments
    email.value = Get.arguments?['email'] ?? '';
    isPasswordReset = Get.arguments?['isPasswordReset'] ?? false;

    // Check if OTP was passed in dev mode
    final devOtp = Get.arguments?['devOtp']?.toString();
    if (devOtp != null && devOtp.length == 6) {
      print('🔑 Auto-filling OTP in dev mode: $devOtp');
      // Auto-fill OTP fields
      otp1Controller.text = devOtp[0];
      otp2Controller.text = devOtp[1];
      otp3Controller.text = devOtp[2];
      otp4Controller.text = devOtp[3];
      otp5Controller.text = devOtp[4];
      otp6Controller.text = devOtp[5];

      // Show snackbar with OTP
      AppFeedback.info('Development Mode', 'OTP auto-filled: $devOtp');
    }

    startResendTimer();
  }

  @override
  void onClose() {
    _isDisposed = true; // Mark as disposed
    otp1Controller.dispose();
    otp2Controller.dispose();
    otp3Controller.dispose();
    otp4Controller.dispose();
    otp5Controller.dispose();
    otp6Controller.dispose();
    otp1Focus.dispose();
    otp2Focus.dispose();
    otp3Focus.dispose();
    otp4Focus.dispose();
    otp5Focus.dispose();
    otp6Focus.dispose();
    super.onClose();
  }

  void startResendTimer() {
    resendTimer.value = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_isDisposed) return false; // Stop if disposed
      if (resendTimer.value > 0) {
        resendTimer.value--;
        return true;
      }
      return false;
    });
  }

  String getOtp() {
    return otp1Controller.text +
        otp2Controller.text +
        otp3Controller.text +
        otp4Controller.text +
        otp5Controller.text +
        otp6Controller.text;
  }

  Future<void> verifyOtp() async {
    final otp = getOtp();

    if (otp.length != 6) {
      AppFeedback.error('Invalid OTP', 'Please enter complete 6-digit OTP');
      return;
    }

    if (isPasswordReset) {
      // For password reset, we don't verify OTP here, we just pass it to the SetPassword screen
      Get.toNamed(
        AppRoutes.setPassword,
        arguments: {
          'email': email.value,
          'token': otp,
        },
      );
      return;
    }

    isLoading.value = true;

    try {
      final response = await _authService.verifyOtp(
        email: email.value,
        otp: otp,
      );

      if (response.success) {
        isLoading.value = false; // Set to false before navigation

        AppFeedback.success('Success', 'Email verified successfully! Welcome!');

        // User is now authenticated - navigate to role-based dashboard
        await Future.delayed(const Duration(milliseconds: 500));

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
            // Default fallback
            Get.offAllNamed(AppRoutes.studentDashboard);
          }
        } else {
          // Fallback if user data not loaded
          Get.offAllNamed(AppRoutes.login);
        }
      } else {
        isLoading.value = false;
        AppFeedback.error('Error', response.message);
      }
    } catch (e) {
      isLoading.value = false;
      AppFeedback.error('Error', e.toString());
    }
  }

  Future<void> resendOtp() async {
    if (resendTimer.value > 0) return;

    isResending.value = true;

    try {
      final response = await _authService.resendOtp(email.value);

      if (response.success) {
        AppFeedback.success('Success', 'OTP sent successfully!');
        startResendTimer();
      } else {
        AppFeedback.error('Error', response.message);
      }
    } catch (e) {
      AppFeedback.error('Error', e.toString());
    } finally {
      isResending.value = false;
    }
  }
}
