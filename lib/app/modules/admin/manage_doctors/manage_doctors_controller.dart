import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/api_service.dart';

class ManageDoctorsController extends GetxController {
  final _apiService = Get.find<ApiService>();

  final RxList<Map<String, dynamic>> doctors = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredDoctors =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  // Filters
  final RxString selectedSpecialization = 'All'.obs;
  final searchController = TextEditingController();

  // Derived list for filter chips
  final RxList<String> specializations = <String>['All'].obs;

  @override
  void onInit() {
    super.onInit();
    loadDoctors();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadDoctors() async {
    isLoading.value = true;
    try {
      final response = await _apiService.get('/Doctors');

      if (response.success && response.data != null) {
        final List<dynamic> data =
            response.data is List ? response.data as List : <dynamic>[];
        doctors.value = data
            .map((item) => item is Map<String, dynamic>
                ? item
                : Map<String, dynamic>.from(item as Map))
            .toList();

        // Extract unique specializations
        final specs = doctors
            .map((d) => d['specialization'] as String?)
            .where((s) => s != null && s.isNotEmpty)
            .toSet()
            .toList();
        specializations.value = ['All', ...specs.cast<String>()];

        filterDoctors();
      } else {
        Get.snackbar('Error', 'Failed to load doctors');
      }
    } catch (e) {
      print('Error loading doctors: $e');
      Get.snackbar('Error', 'A network error occurred');
    } finally {
      isLoading.value = false;
    }
  }

  void filterDoctors() {
    var result = doctors.toList();

    // Specialization filter
    if (selectedSpecialization.value != 'All') {
      result = result
          .where((doc) => doc['specialization'] == selectedSpecialization.value)
          .toList();
    }

    // Search filter
    if (searchController.text.isNotEmpty) {
      final query = searchController.text.toLowerCase();
      result = result.where((doc) {
        final user = doc['user'] ?? {};
        final name = (user['fullName'] ?? '').toLowerCase();
        final email = (user['email'] ?? '').toLowerCase();
        final specialization = (doc['specialization'] ?? '').toLowerCase();

        return name.contains(query) ||
            email.contains(query) ||
            specialization.contains(query);
      }).toList();
    }

    filteredDoctors.value = result;
  }

  void updateSearch(String value) {
    filterDoctors();
  }

  void setFilter(String filter) {
    selectedSpecialization.value = filter;
    filterDoctors();
  }

  Future<void> deleteDoctor(int userId) async {
    try {
      // We delete the User, which deletes the Doctor profile
      final response = await _apiService.delete('/Admin/users/$userId');

      if (response.success) {
        Get.snackbar('success', 'doctor_deleted_successfully',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM);
        loadDoctors(); // Reload list
      } else {
        Get.snackbar('error', response.message);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete doctor');
    }
  }

  Color getAvailabilityColor(bool? isAvailable) {
    return (isAvailable == true) ? Colors.green : Colors.red;
  }
}
