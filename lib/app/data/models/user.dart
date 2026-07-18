import 'app_roles.dart';

class User {
  final String id;
  String name; // Made mutable for profile updates
  final String email;
  final String role; // Student, Doctor, Admin, Faculty
  final String? department;
  final bool emailVerified;

  String? phone; // Made mutable
  final String? profileImage;
  final String? cmsId; // CMS ID for all users

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.department, // Optional for Doctors and Admins
    required this.emailVerified, // Default to false

    this.phone, // Optional
    this.profileImage,
    this.cmsId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
        // FIX: Check for 'userId' (from API) OR 'id' (from local storage)
        id: (json['userId'] ?? json['id'])?.toString() ?? "",
        name: json['fullName'] ?? json['name'] ?? '', // Check both just in case
        email: json['email'] ?? '',
        role: json['role'] ?? 'Student',
        department: json['department'],
        emailVerified:
            json['isEmailVerified'] ?? json['emailVerified'] ?? false,
        phone: json['phoneNumber'] ?? json['phone'],
        profileImage: json['profileImageUrl'] ?? json['profileImage'],
        cmsId: json['registrationNumber'] ?? json['cmsId']);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'emailVerified': emailVerified,
      'phone': phone,
      'profileImage': profileImage,
      'cmsId': cmsId,
    };
  }

  bool get isStudent => AppRoles.normalize(role) == AppRoles.student;
  bool get isFaculty => AppRoles.normalize(role) == AppRoles.faculty;
  bool get isDoctor => AppRoles.normalize(role) == AppRoles.doctor;
  bool get isAdmin => AppRoles.normalize(role) == AppRoles.admin;
  bool get isStudentOrFaculty => isStudent || isFaculty;
}
