import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/api_service.dart';

class ManageUsersController extends GetxController {
  final _apiService = Get.find<ApiService>();

  final RxList<Map<String, dynamic>> users = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredUsers =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  // Filters
  final RxString selectedFilter = 'All'.obs;
  final searchController = TextEditingController();

  int _page = 1;
  final int _limit = 20;
  final RxBool hasMore = true.obs;
  final RxBool isLoadingMore = false.obs;
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is Map && args['role'] != null) {
      selectedFilter.value = args['role'];
    }
    loadUsers();

    scrollController.addListener(() {
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 50) {
        loadMoreUsers();
      }
    });
  }

  @override
  void onClose() {
    scrollController.dispose();
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadUsers() async {
    _page = 1;
    hasMore.value = true;
    isLoading.value = true;
    try {
      final role = selectedFilter.value != 'All' ? '&role=${selectedFilter.value}' : '';
      final search = searchController.text.isNotEmpty ? '&search=${searchController.text}' : '';
      final response = await _apiService.get('/Admin/users?page=$_page&limit=$_limit$role$search');

      if (response.success && response.data != null) {
        final Map<String, dynamic> data = response.data as Map<String, dynamic>;
        final List<dynamic> items = data['items'] as List<dynamic>;
        final int totalCount = data['totalCount'] as int;

        users.value = items
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        
        hasMore.value = users.length < totalCount;
        filterUsers();
      } else {
        Get.snackbar('Error', 'Failed to load users');
      }
    } catch (e) {
      print('Error loading users: $e');
      Get.snackbar('Error', 'A network error occurred');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreUsers() async {
    if (isLoadingMore.value || !hasMore.value || isLoading.value) return;

    isLoadingMore.value = true;
    _page++;
    try {
      final role = selectedFilter.value != 'All' ? '&role=${selectedFilter.value}' : '';
      final search = searchController.text.isNotEmpty ? '&search=${searchController.text}' : '';
      final response = await _apiService.get('/Admin/users?page=$_page&limit=$_limit$role$search');

      if (response.success && response.data != null) {
        final Map<String, dynamic> data = response.data as Map<String, dynamic>;
        final List<dynamic> items = data['items'] as List<dynamic>;
        final int totalCount = data['totalCount'] as int;

        final newUsers = items
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        
        users.addAll(newUsers);
        hasMore.value = users.length < totalCount;
        filterUsers();
      }
    } catch (e) {
      print('Error loading more users: $e');
      _page--; // Revert page if failed
    } finally {
      isLoadingMore.value = false;
    }
  }

  void filterUsers() {
    var result = users.toList();

    // Role filter
    if (selectedFilter.value != 'All') {
      result =
          result.where((user) => user['role'] == selectedFilter.value).toList();
    }

    // Search filter
    if (searchController.text.isNotEmpty) {
      final query = searchController.text.toLowerCase();
      result = result.where((user) {
        final name = (user['fullName'] ?? '').toLowerCase();
        final email = (user['email'] ?? '').toLowerCase();
        final regNum = (user['registrationNumber'] ?? '').toLowerCase();

        return name.contains(query) ||
            email.contains(query) ||
            regNum.contains(query);
      }).toList();
    }

    filteredUsers.value = result;
  }

  void updateSearch(String value) {
    filterUsers();
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
    filterUsers();
  }

  Future<void> createUser(Map<String, dynamic> userData) async {
    isLoading.value = true;
    try {
      // Backend expects proper JSON types
      final response = await _apiService.post('/Admin/users', data: userData);

      if (response.success) {
        Get.snackbar(
          'success',
          'user_created_successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        loadUsers(); // Reload list
      } else {
        Get.snackbar(
          'error',
          response.message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('Error creating user: $e');
      Get.snackbar('Error', 'Failed to create user');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateUser(int id, Map<String, dynamic> userData) async {
    isLoading.value = true;
    try {
      final response = await _apiService.put('/Admin/users/$id', data: userData);

      if (response.success) {
        Get.snackbar(
          'success',
          'user_updated_successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        loadUsers(); // Reload list
      } else {
        Get.snackbar(
          'error',
          response.message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('Error updating user: $e');
      Get.snackbar('Error', 'Failed to update user');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      final response = await _apiService.delete('/Admin/users/$id');

      if (response.success) {
        Get.snackbar(
          'success',
          'user_deleted_successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        loadUsers(); // Reload list
      } else {
        Get.snackbar('error', response.message);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete user');
    }
  }

  Future<void> toggleUserStatus(int id) async {
    final user = users.firstWhere((u) => u['id'] == id, orElse: () => {});
    if (user.isEmpty) return;

    final updatedData = {
      'fullName': user['fullName'], // Required field
      'isActive': !(user['isActive'] ?? false),
    };

    await updateUser(id, updatedData);
  }

  Color getStatusColor(bool isActive) {
    return isActive ? Colors.green : Colors.red;
  }

  Future<List<Map<String, dynamic>>> fetchUserEmergencyContacts(int userId) async {
    try {
      final response = await _apiService.get('/EmergencyContacts/user/$userId');
      if (response.success && response.data != null) {
        if (response.data is List) {
          return (response.data as List)
              .map((item) => item is Map<String, dynamic>
                  ? item
                  : Map<String, dynamic>.from(item as Map))
              .toList();
        }
      }
    } catch (e) {
      print('Error loading emergency contacts: $e');
    }
    return [];
  }
}

