import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../config/app_theme.dart';
import '../../../../app/services/auth_service.dart';
import '../../../../app/services/doctor_service.dart';
import '../../../../app/widgets/app_feedback.dart';
import 'profile_controller.dart';

export 'profile_binding.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Doctor fields
  final _specializationController = TextEditingController();
  final _roomController = TextEditingController();
  final _bioController = TextEditingController();
  bool isAvailable = false;
  bool isDoctor = false;

  bool isEditMode = false;
  bool showPasswordSection = false;

  late final ProfileController profileController;

  final authService = Get.find<AuthService>();
  DoctorService? doctorService;

  @override
  void initState() {
    super.initState();
    profileController = Get.find<ProfileController>();
    final user = authService.currentUser.value;
    _nameController.text = user?.name ?? '';
    _phoneController.text = user?.phone ?? '';

    isDoctor = user?.role.toLowerCase() == 'doctor';
    if (isDoctor) {
      if (Get.isRegistered<DoctorService>()) {
        doctorService = Get.find<DoctorService>();
        _loadDoctorProfile();
      }
    }
  }

  Future<void> _loadDoctorProfile() async {
    if (doctorService == null) return;
    try {
      final response = await doctorService!.getMyProfile();
      if (response.success && response.data != null) {
        final data = response.data!;
        // Handle User object if present
        if (data.containsKey('user')) {
          final user = data['user'];
          if (user != null) {
            _nameController.text = user['fullName'] ?? '';
            _phoneController.text = user['phoneNumber'] ?? '';
          }
        }
        setState(() {
          _specializationController.text = data['specialization'] ?? '';
          _roomController.text = data['roomNumber'] ?? '';
          _bioController.text = data['bio'] ?? '';
          isAvailable = data['isAvailable'] == true;
        });
      }
    } catch (e) {
      print('Error loading doctor profile: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _specializationController.dispose();
    _roomController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      if (isDoctor && doctorService != null) {
        // Save doctor profile
        final data = {
          'FullName': _nameController.text,
          'PhoneNumber': _phoneController.text,
          'Specialization': _specializationController.text,
          'RoomNumber': _roomController.text,
          'Bio': _bioController.text,
          'IsAvailable': isAvailable,
        };

        final response = await doctorService!.updateProfile(data);
        if (response.success) {
          _showSuccess('Profile updated successfully');
          // Update local auth state if name changed
          if (authService.currentUser.value != null) {
            final updatedUser = authService.currentUser.value!;
            updatedUser.name = _nameController.text;
            updatedUser.phone = _phoneController.text;
            authService.currentUser.refresh();
          }
        } else {
          _showError(response.message);
        }
      } else {
        final response = await authService.updateProfile(
          name: _nameController.text,
          phone: _phoneController.text,
          department: authService.currentUser.value?.department,
        );

        if (response.success) {
          _showSuccess('Profile updated successfully');
          await authService.getCurrentUser();
        } else {
          _showError(response.message);
          return;
        }
      }
      setState(() => isEditMode = false);
    } catch (e) {
      _showError('Failed to update profile');
    }
  }

  void _showSuccess(String msg) {
    AppFeedback.success('Success', msg);
  }

  void _showError(String msg) {
    AppFeedback.error('Error', msg);
  }

  void _changePassword() {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      AppFeedback.error('Error', 'Passwords do not match');
      return;
    }

    AppFeedback.success('Success', 'Password changed successfully');

    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    setState(() => showPasswordSection = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser.value;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.surface,
        actions: [
          if (!isEditMode)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => isEditMode = true),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Picture
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundColor: AppTheme.primary,
              child: Builder(builder: (context) {
                final role = user?.role.toLowerCase() ?? '';
                IconData iconData;
                switch (role) {
                  case 'doctor':
                    iconData = Icons.medical_information;
                    break;
                  case 'admin':
                    iconData = Icons.admin_panel_settings;
                    break;
                  case 'faculty':
                    iconData = Icons.badge;
                    break;
                  case 'student':
                  default:
                    iconData = Icons.school;
                    break;
                }
                return Icon(iconData, size: 60, color: AppTheme.surface);
              }),
            ),
          ),
          const SizedBox(height: 24),

          // Personal Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personal information',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      enabled: isEditMode,
                      decoration: InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: user?.email ?? '',
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      enabled: isEditMode,
                      decoration: InputDecoration(
                        labelText: 'Phone number',
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    if (user?.role.toLowerCase() == 'student') ...[
                      TextFormField(
                        initialValue: user?.cmsId ?? '',
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'CMS ID',
                          prefixIcon: const Icon(Icons.badge),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      initialValue: user?.department ?? '',
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Department',
                        prefixIcon: const Icon(Icons.school),
                      ),
                    ),
                    if (isDoctor) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Doctor details',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _specializationController,
                        decoration: InputDecoration(
                          labelText: 'Specialization',
                          prefixIcon:
                              const Icon(Icons.medical_services_outlined),
                        ),
                        enabled: isEditMode,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _roomController,
                        decoration: InputDecoration(
                          labelText: 'Room number',
                          prefixIcon: const Icon(Icons.meeting_room_outlined),
                        ),
                        enabled: isEditMode,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bioController,
                        decoration: InputDecoration(
                          labelText: 'Bio',
                          prefixIcon: const Icon(Icons.description_outlined),
                        ),
                        enabled: isEditMode,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Available for appointments'),
                        value: isAvailable,
                        onChanged: isEditMode
                            ? (val) => setState(() => isAvailable = val)
                            : null,
                        secondary: const Icon(Icons.check_circle_outline),
                      ),
                    ],
                    if (isEditMode) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() => isEditMode = false);
                              _nameController.text = user?.name ?? '';
                              _phoneController.text = user?.phone ?? '';
                            },
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Save changes'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Security
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Security',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(
                              () => showPasswordSection = !showPasswordSection);
                        },
                        icon: Icon(
                          showPasswordSection
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                        label: const Text('Change password'),
                      ),
                    ],
                  ),
                  if (showPasswordSection) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _currentPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Current password',
                        prefixIcon: const Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _newPasswordController,
                      decoration: InputDecoration(
                        labelText: 'New password',
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirm new password',
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Update password'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
