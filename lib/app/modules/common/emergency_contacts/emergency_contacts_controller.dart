import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medi_ai/config/app_config.dart';
import 'package:medi_ai/app/data/models/emergency_contact.dart';
import 'package:medi_ai/app/services/api_service.dart';

class EmergencyContactsController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final contactsList = <EmergencyContact>[].obs;
  final isLoading = true.obs;

  final nameController = TextEditingController();
  final relationController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchContacts();
  }

  @override
  void onClose() {
    nameController.dispose();
    relationController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    super.onClose();
  }

  Future<void> fetchContacts() async {
    isLoading.value = true;
    try {
      final response = await _apiService.get<List<dynamic>>(
        '${AppConfig.baseUrl}/EmergencyContacts',
      );

      if (response.success && response.data != null) {
        contactsList.value = (response.data as List)
            .map((e) => EmergencyContact.fromJson(e))
            .toList();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load contacts');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addContact() async {
    if (nameController.text.isEmpty || phoneController.text.isEmpty) {
      Get.snackbar('Error', 'Name and Phone are required');
      return;
    }

    if (emailController.text.isNotEmpty &&
        !GetUtils.isEmail(emailController.text)) {
      Get.snackbar('Error', 'Invalid Email Address');
      return;
    }

    try {
      final data = {
        'contactName': nameController.text,
        'relationship': relationController.text,
        'phoneNumber': phoneController.text,
        'email': emailController.text.isNotEmpty ? emailController.text : null,
        'address':
            addressController.text.isNotEmpty ? addressController.text : null,
      };

      final response = await _apiService.post<dynamic>(
        '${AppConfig.baseUrl}/EmergencyContacts',
        data: data,
      );

      if (response.success) {
        Get.back();
        Get.snackbar('Success', 'Contact added');
        _clearForm();
        fetchContacts();
      } else {
        Get.snackbar('Error', response.message);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to add contact');
    }
  }

  Future<void> deleteContact(int id) async {
    try {
      final response = await _apiService
          .delete<dynamic>('${AppConfig.baseUrl}/EmergencyContacts/$id');
      if (response.success) {
        fetchContacts();
      } else {
        Get.snackbar('Error', response.message);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete contact');
    }
  }

  void _clearForm() {
    nameController.clear();
    relationController.clear();
    phoneController.clear();
    emailController.clear();
    addressController.clear();
  }
}
