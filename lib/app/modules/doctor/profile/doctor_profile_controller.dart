import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../app/services/auth_service.dart';
import '../../../../app/services/doctor_service.dart';
import '../../../../app/services/api_service.dart';
import '../../../../app/widgets/app_feedback.dart';

class DoctorProfileController extends GetxController {
  final AuthService authService = Get.find<AuthService>();
  final DoctorService doctorService = Get.find<DoctorService>();
  final ApiService _apiService = Get.find<ApiService>();

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final specializationController = TextEditingController();
  final roomController = TextEditingController();
  final bioController = TextEditingController();

  final RxBool isAvailable = false.obs;
  final RxBool isEditMode = false.obs;
  final RxBool showPasswordSection = false.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final user = authService.currentUser.value;
    nameController.text = user?.name ?? '';
    phoneController.text = user?.phone ?? '';
    loadDoctorProfile();
  }

  Future<void> loadDoctorProfile() async {
    isLoading.value = true;
    try {
      final response = await doctorService.getMyProfile();
      if (response.success && response.data != null) {
        final data = response.data!;
        if (data.containsKey('user')) {
          final user = data['user'];
          if (user != null) {
            nameController.text = user['fullName'] ?? '';
            phoneController.text = user['phoneNumber'] ?? '';
          }
        }
        specializationController.text = data['specialization'] ?? '';
        roomController.text = data['roomNumber'] ?? '';
        bioController.text = data['bio'] ?? '';
        isAvailable.value = data['isAvailable'] == true;
      }
    } catch (e) {
      print('Error loading doctor profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void toggleEditMode() {
    isEditMode.value = !isEditMode.value;
    if (!isEditMode.value) {
      // Re-load if cancelled to discard changes
      loadDoctorProfile();
    }
  }

  void togglePasswordSection() {
    showPasswordSection.value = !showPasswordSection.value;
  }

  Future<void> saveProfile() async {
    if (!formKey.currentState!.validate()) return;
    isLoading.value = true;

    try {
      final data = {
        'FullName': nameController.text,
        'PhoneNumber': phoneController.text,
        'Specialization': specializationController.text,
        'RoomNumber': roomController.text,
        'Bio': bioController.text,
        'IsAvailable': isAvailable.value,
      };

      final response = await doctorService.updateProfile(data);
      if (response.success) {
        AppFeedback.success('Success', 'Profile updated successfully');
        if (authService.currentUser.value != null) {
          final updatedUser = authService.currentUser.value!;
          updatedUser.name = nameController.text;
          updatedUser.phone = phoneController.text;
          authService.currentUser.refresh();
        }
        isEditMode.value = false;
      } else {
        AppFeedback.error('Error', response.message);
      }
    } catch (e) {
      AppFeedback.error('Error', 'Failed to update profile');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> changePassword() async {
    if (newPasswordController.text != confirmPasswordController.text) {
      AppFeedback.error('Error', 'Passwords do not match');
      return;
    }

    if (currentPasswordController.text.isEmpty || newPasswordController.text.isEmpty) {
      AppFeedback.error('Error', 'Please fill out all password fields');
      return;
    }

    isLoading.value = true;
    try {
      final response = await _apiService.post<Object>(
        '/Users/change-password',
        data: {
          'CurrentPassword': currentPasswordController.text,
          'NewPassword': newPasswordController.text,
        },
      );

      if (response.success) {
        AppFeedback.success('Success', 'Password changed successfully');
        currentPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();
        showPasswordSection.value = false;
      } else {
        AppFeedback.error('Error', response.message);
      }
    } catch (e) {
      AppFeedback.error('Error', 'Failed to change password');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    specializationController.dispose();
    roomController.dispose();
    bioController.dispose();
    super.onClose();
  }
}
