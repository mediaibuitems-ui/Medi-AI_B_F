import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'emergency_contacts_controller.dart';
import 'package:medi_ai/config/app_theme.dart';

class EmergencyContactsScreen extends GetView<EmergencyContactsController> {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.contactsList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.perm_contact_calendar,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No emergency contacts',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.contactsList.length,
          itemBuilder: (context, index) {
            final contact = controller.contactsList[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: Text(
                    contact.contactName.isNotEmpty
                        ? contact.contactName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(contact.contactName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${contact.relationship} • ${contact.phoneNumber}'),
                    if (contact.email?.isNotEmpty == true) Text(contact.email!),
                    if (contact.address?.isNotEmpty == true)
                      Text(contact.address!),
                  ],
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(contact.id),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _confirmDelete(int id) {
    Get.defaultDialog(
      title: 'Delete Contact',
      middleText: 'Are you sure you want to delete this contact?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.deleteContact(id);
      },
    );
  }

  void _showAddDialog() {
    controller.nameController.clear();
    controller.relationController.clear();
    controller.phoneController.clear();
    controller.emailController.clear();
    controller.addressController.clear();

    Get.defaultDialog(
      title: 'Add Contact',
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: controller.nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: controller.relationController,
              decoration: const InputDecoration(labelText: 'Relationship'),
            ),
            TextField(
              controller: controller.phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: controller.emailController,
              decoration: const InputDecoration(labelText: 'Email (Optional)'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: controller.addressController,
              decoration:
                  const InputDecoration(labelText: 'Address (Optional)'),
              keyboardType: TextInputType.streetAddress,
            ),
          ],
        ),
      ),
      textConfirm: 'Save',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () => controller.addContact(),
    );
  }
}
