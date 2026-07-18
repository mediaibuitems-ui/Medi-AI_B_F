import 'package:flutter/material.dart';
import '../../../data/models/app_roles.dart';
import 'package:get/get.dart';
import '../../../../config/app_theme.dart';
import 'manage_users_controller.dart';
import 'widgets/user_form_dialog.dart';

class ManageUsersScreen extends GetView<ManageUsersController> {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppTheme.textPrimary,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.dialog(
          UserFormDialog(
            onSubmit: (data) => controller.createUser(data),
          ),
        ),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Header with Filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.textPrimary.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: controller.searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppTheme.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: controller.updateSearch,
                ),
                const SizedBox(height: 16),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(controller, 'All'),
                      const SizedBox(width: 8),
                      _buildFilterChip(controller, 'Student'),
                      const SizedBox(width: 8),
                      _buildFilterChip(controller, 'Doctor'),
                      const SizedBox(width: 8),
                      _buildFilterChip(controller, 'Faculty'),
                      const SizedBox(width: 8),
                      _buildFilterChip(controller, AppRoles.admin),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.filteredUsers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person_off_outlined,
                        size: 64,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No users found',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.loadUsers,
                child: ListView.builder(
                  controller: controller.scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.filteredUsers.length +
                      1, // +1 for loading indicator
                  itemBuilder: (context, index) {
                    if (index == controller.filteredUsers.length) {
                      return Obx(() {
                        if (controller.isLoadingMore.value) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (!controller.hasMore.value &&
                            controller.filteredUsers.isNotEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(child: Text('No more users')),
                          );
                        }
                        return const SizedBox.shrink();
                      });
                    }

                    final user = controller.filteredUsers[index];
                    return _buildUserCard(context, controller, user);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(ManageUsersController controller, String label) {
    return Obx(() {
      final isSelected = controller.selectedFilter.value == label;
      return FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          if (selected) controller.setFilter(label);
        },
        backgroundColor: AppTheme.surface,
        selectedColor: AppTheme.primary.withOpacity(0.1),
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: AppTheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? AppTheme.primary
                : AppTheme.border.withOpacity(0.25),
          ),
        ),
      );
    });
  }

  Widget _buildUserCard(BuildContext context, ManageUsersController controller,
      Map<String, dynamic> user) {
    final isActive = user['isActive'] == true;
    final role = user['role'] ?? 'Unknown';
    final name = user['fullName'] ?? 'No name';
    final email = user['email'] ?? 'No email';
    final id = user['id']; // Should be int

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Get.dialog(
            UserFormDialog(
              user: user,
              onSubmit: (data) => controller.updateUser(id, data),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$role â€¢ $email',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.contact_phone,
                        color: AppTheme.primary),
                    onPressed: () => _showEmergencyContactsDialog(
                        context, controller, id, name),
                    tooltip: 'Emergency Contacts',
                  ),
                  IconButton(
                    icon: Icon(
                      isActive ? Icons.check_circle : Icons.cancel,
                      color:
                          isActive ? AppTheme.success : AppTheme.textSecondary,
                    ),
                    onPressed: () => controller.toggleUserStatus(id),
                    tooltip: isActive ? 'Deactivate' : 'Activate',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppTheme.error),
                    onPressed: () => _confirmDelete(controller, id),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(ManageUsersController controller, int id) {
    Get.defaultDialog(
      title: 'Confirm Delete',
      middleText: 'Are you sure you want to delete this user?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: AppTheme.surface,
      onConfirm: () {
        Get.back(); // Close dialog
        controller.deleteUser(id);
      },
    );
  }

  void _showEmergencyContactsDialog(BuildContext context,
      ManageUsersController controller, int userId, String userName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$userName\'s Emergency Contacts',
              style: const TextStyle(fontSize: 18)),
          backgroundColor: AppTheme.surface,
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: controller.fetchUserEmergencyContacts(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox(
                    height: 100,
                    child: Center(child: Text('No emergency contacts found.')),
                  );
                }

                final contacts = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    final name = contact['contactName'] ??
                        contact['ContactName'] ??
                        'Unknown';
                    final relation = contact['relationship'] ??
                        contact['Relationship'] ??
                        'N/A';
                    final phone = contact['phoneNumber'] ??
                        contact['PhoneNumber'] ??
                        'N/A';

                    return Card(
                      color: AppTheme.background,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side:
                            BorderSide(color: AppTheme.border.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.contact_phone,
                            color: AppTheme.primary),
                        title: Text('$name ($relation)',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(phone),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
