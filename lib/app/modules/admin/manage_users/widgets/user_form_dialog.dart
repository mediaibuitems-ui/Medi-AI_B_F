import 'package:flutter/material.dart';
import '../../../../data/models/app_roles.dart';
import 'package:get/get.dart';
import '../../../../../config/app_theme.dart';

class UserFormDialog extends StatefulWidget {
  final Map<String, dynamic>? user;
  final Function(Map<String, dynamic>) onSubmit;

  const UserFormDialog({super.key, this.user, required this.onSubmit});

  @override
  _UserFormDialogState createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _role;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _fullNameController;
  late TextEditingController _departmentController;
  late TextEditingController _regNumController;
  late TextEditingController _phoneController;
  // Doctor specific
  late TextEditingController _specializationController;
  late TextEditingController _licenseController;
  late TextEditingController _experienceController;

  @override
  void initState() {
    super.initState();
    _role = widget.user?['role'] ?? AppRoles.student;
    _emailController = TextEditingController(text: widget.user?['email'] ?? '');
    _passwordController =
        TextEditingController(); // Empty for edit unless changed
    _fullNameController =
        TextEditingController(text: widget.user?['fullName'] ?? '');
    _departmentController =
        TextEditingController(text: widget.user?['department'] ?? '');
    _regNumController =
        TextEditingController(text: widget.user?['registrationNumber'] ?? '');
    _phoneController =
        TextEditingController(text: widget.user?['phoneNumber'] ?? '');

    // Doctor fields
    _specializationController = TextEditingController();
    _licenseController = TextEditingController();
    _experienceController = TextEditingController();

    if (widget.user != null) {
      // Since backend might return nested fields differently, adjust if needed
      // Assuming user map might have doctorDetails directly or flattened
      // You might need to adjust this depending on how GetUser returns data
      // For now, let's assume flat structure or leave blank for edit if not in list
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _departmentController.dispose();
    _regNumController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _licenseController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        width: 500,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withOpacity(0.03),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit User' : 'Add New User',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                ),
                const SizedBox(height: 24),

                // Role Selection
                if (!isEdit) ...[
                  DropdownButtonFormField<String>(
                    value: _role,
                    decoration: _inputDecoration('Role'),
                    items: [
                      AppRoles.student,
                      AppRoles.faculty,
                      AppRoles.doctor,
                      AppRoles.admin
                    ]
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (val) => setState(() => _role = val!),
                  ),
                  const SizedBox(height: 16),
                ],

                // Common Fields
                TextFormField(
                  controller: _fullNameController,
                  decoration: _inputDecoration('Full name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                if (!isEdit) ...[
                  TextFormField(
                    controller: _emailController,
                    decoration: _inputDecoration('Email'),
                    validator: (v) =>
                        v!.isEmpty || !v.contains('@') ? 'Invalid email' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: _inputDecoration('Password'),
                    obscureText: true,
                    validator: (v) => v!.isEmpty || v.length < 6
                        ? 'Minimum 6 characters'
                        : null,
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _phoneController,
                  decoration: _inputDecoration('Phone number'),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _departmentController,
                  decoration: _inputDecoration('Department'),
                ),
                const SizedBox(height: 16),

                // Conditional Fields based on Role
                if (_role == AppRoles.student || _role == AppRoles.faculty) ...[
                  TextFormField(
                    controller: _regNumController,
                    decoration: _inputDecoration(_role == AppRoles.student
                        ? 'Registration number'
                        : 'Employee ID'),
                  ),
                  const SizedBox(height: 16),
                ],

                if (_role == AppRoles.doctor) ...[
                  TextFormField(
                    controller: _specializationController,
                    decoration: _inputDecoration('Specialization'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _licenseController,
                    decoration: _inputDecoration('License number'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _experienceController,
                          decoration: _inputDecoration('Experience years'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.surface,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final data = {
                            'fullName': _fullNameController.text,
                            'role': _role,
                            'phoneNumber': _phoneController.text,
                            'department': _departmentController.text,
                            'registrationNumber': _regNumController.text,
                            'isActive': widget.user?['isActive'] ??
                                true, // Preserve or default
                            'isEmailVerified':
                                widget.user?['isEmailVerified'] ??
                                    true, // Preserve or default
                          };

                          if (!isEdit) {
                            data['email'] = _emailController.text;
                            data['password'] = _passwordController.text;
                          }

                          if (_role == AppRoles.doctor) {
                            data['specialization'] =
                                _specializationController.text;
                            data['licenseNumber'] = _licenseController.text;
                            data['experienceYears'] =
                                int.tryParse(_experienceController.text) ?? 0;
                          }

                          widget.onSubmit(data);
                          Get.back();
                        }
                      },
                      child: Text(isEdit ? 'Save Changes' : 'Create User'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppTheme.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.border.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.45)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
