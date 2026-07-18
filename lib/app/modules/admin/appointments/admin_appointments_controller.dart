import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medi_ai/app/data/models/appointment.dart';
import 'package:medi_ai/app/services/api_service.dart';

class AdminAppointmentsController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final RxList<Appointment> allAppointments = <Appointment>[].obs;
  final RxList<Appointment> filteredAppointments = <Appointment>[].obs;
  final RxBool isLoading = true.obs;

  final RxString selectedFilter = 'All'.obs;
  final List<String> filterOptions = [
    'All',
    'Pending',
    'Confirmed',
    'Completed',
    'Cancelled'
  ];

  int _page = 1;
  final int _limit = 20;
  final RxBool hasMore = true.obs;
  final RxBool isLoadingMore = false.obs;
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    loadAppointments();
    scrollController.addListener(() {
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 50) {
        loadMoreAppointments();
      }
    });
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  Future<void> loadAppointments() async {
    _page = 1;
    hasMore.value = true;
    isLoading.value = true;
    try {
      final response = await _apiService.get('/Appointments?page=$_page&limit=$_limit');
      if (response.success && response.data != null) {
        final Map<String, dynamic> data = response.data;
        final List<dynamic> list = data['items'];
        final int totalCount = data['totalCount'];

        allAppointments.value = list.map((json) => Appointment.fromJson(json)).toList();
        hasMore.value = allAppointments.length < totalCount;
        _applyFilter();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load appointments');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreAppointments() async {
    if (isLoadingMore.value || !hasMore.value || isLoading.value) return;

    isLoadingMore.value = true;
    _page++;
    try {
      final response = await _apiService.get('/Appointments?page=$_page&limit=$_limit');
      if (response.success && response.data != null) {
        final Map<String, dynamic> data = response.data;
        final List<dynamic> list = data['items'];
        final int totalCount = data['totalCount'];

        final newAppointments = list.map((json) => Appointment.fromJson(json)).toList();
        allAppointments.addAll(newAppointments);
        hasMore.value = allAppointments.length < totalCount;
        _applyFilter();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load more appointments');
      _page--;
    } finally {
      isLoadingMore.value = false;
    }
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
    _applyFilter();
  }

  void _applyFilter() {
    if (selectedFilter.value == 'All') {
      filteredAppointments.value = allAppointments;
    } else {
      filteredAppointments.value = allAppointments
          .where((a) => a.status == selectedFilter.value)
          .toList();
    }
  }

  void viewAppointmentDetails(Appointment appointment) {
    Get.toNamed('/appointment-detail', arguments: {'appointment': appointment});
  }

  Future<void> deleteAppointment(String id) async {
    try {
      final response = await _apiService.delete('/Appointments/$id');
      if (response.success) {
        Get.snackbar('Success', 'Appointment deleted/cancelled successfully');
        await loadAppointments();
      } else {
        Get.snackbar('Error', response.message);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete appointment');
    }
  }
}
