import 'package:flutter/foundation.dart';

class AppRoles {
  static const String admin = 'Admin';
  static const String doctor = 'Doctor';
  static const String faculty = 'Faculty';
  static const String student = 'Student';

  // Helper method to safely parse roles if needed
  static String normalize(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return admin;
      case 'doctor':
        return doctor;
      case 'faculty':
        return faculty;
      case 'student':
        return student;
      default:
        return role;
    }
  }
}
