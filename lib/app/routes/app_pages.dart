import 'package:get/get.dart';
import '../modules/auth/splash/splash_screen.dart';
import '../modules/auth/splash/splash_binding.dart';
import '../modules/auth/onboarding/onboarding_screen.dart';
import '../modules/auth/onboarding/onboarding_binding.dart';
import '../modules/auth/register_email/register_email_screen.dart';
import '../modules/auth/register_email/register_email_binding.dart';
import '../modules/auth/otp_verification/otp_verification_screen.dart';
import '../modules/auth/otp_verification/otp_verification_binding.dart';
import '../modules/auth/set_password/set_password_screen.dart';
import '../modules/auth/set_password/set_password_binding.dart';
import '../modules/auth/login/login_screen.dart';
import '../modules/auth/login/login_binding.dart';
import '../modules/auth/forgot_password/forgot_password_screen.dart';
import '../modules/auth/forgot_password/forgot_password_binding.dart';

// Student screens
import '../modules/student/dashboard/student_dashboard_screen.dart';
import '../modules/student/dashboard/student_dashboard_binding.dart';
import '../modules/student/book_appointment/book_appointment_screen.dart';
import '../modules/student/book_appointment/book_appointment_binding.dart';
import '../modules/student/my_appointments/my_appointments_screen.dart';
import '../modules/student/my_appointments/my_appointments_binding.dart';
import '../modules/student/health_analyzer/health_analyzer_screen.dart';
import '../modules/student/health_analyzer/health_analyzer_binding.dart';
import '../modules/student/medicine_reminders/medicine_reminders_screen.dart';
import '../modules/student/medicine_reminders/medicine_reminders_binding.dart';
import '../modules/student/profile/profile_screen.dart';
import '../modules/student/profile/profile_binding.dart';
import '../modules/student/medical_history/medical_history_screen.dart';
import '../modules/student/medical_history/medical_history_binding.dart';
import '../modules/student/prescription_history/prescription_history_screen.dart';
import '../modules/student/prescription_history/prescription_history_binding.dart';
import '../modules/student/emergency_contacts/emergency_contacts_screen.dart';
import '../modules/student/emergency_contacts/emergency_contacts_binding.dart';
import '../modules/common/feedback/feedback_screen.dart';
import '../modules/common/feedback/feedback_binding.dart';

// Doctor screens
import '../modules/doctor/dashboard/doctor_dashboard_screen.dart';
import '../modules/doctor/dashboard/doctor_dashboard_binding.dart';
import '../modules/doctor/today_appointments/today_appointments_screen.dart';
import '../modules/doctor/today_appointments/today_appointments_binding.dart';
import '../modules/doctor/patient_detail/patient_detail_screen.dart';
import '../modules/doctor/patient_detail/patient_detail_binding.dart';
import '../modules/doctor/write_prescription/write_prescription_screen.dart';
import '../modules/doctor/write_prescription/write_prescription_binding.dart';
import '../modules/doctor/patients/patients_screen.dart';
import '../modules/doctor/patients/patients_binding.dart';
import '../modules/doctor/schedule/schedule_screen.dart';
import '../modules/doctor/schedule/schedule_binding.dart';
import '../modules/doctor/booking_settings/booking_settings_screen.dart';
import '../modules/doctor/booking_settings/booking_settings_binding.dart';
import '../modules/doctor/profile/doctor_profile_screen.dart';
import '../modules/doctor/profile/doctor_profile_binding.dart';
import '../modules/doctor/settings/doctor_settings_screen.dart';
import '../modules/doctor/settings/doctor_settings_binding.dart';
import '../modules/doctor/leaves/doctor_leaves_screen.dart';
import '../modules/doctor/leaves/doctor_leaves_binding.dart';
// Common
import '../modules/common/appointment_detail_screen.dart';

// Faculty screens
import '../modules/faculty/dashboard/faculty_dashboard_screen.dart';
import '../modules/faculty/dashboard/faculty_dashboard_binding.dart';

// Common notifications
import '../modules/common/notifications/notifications_screen.dart';
import '../modules/common/notifications/notifications_binding.dart';
import '../modules/common/settings/settings_screen.dart';
import '../modules/common/settings/settings_binding.dart';

// Admin screens
import '../modules/admin/dashboard/admin_dashboard_screen.dart';
import '../modules/admin/dashboard/admin_dashboard_binding.dart';
import '../modules/admin/manage_users/manage_users_screen.dart';
import '../modules/admin/manage_users/manage_users_binding.dart';
import '../modules/admin/manage_doctors/manage_doctors_screen.dart';
import '../modules/admin/manage_doctors/manage_doctors_binding.dart';
import '../modules/admin/manage_feedback/manage_feedback_screen.dart';
import '../modules/admin/manage_feedback/manage_feedback_binding.dart';
import '../modules/admin/reports/reports_screen.dart';
import '../modules/admin/system_settings/system_settings_screen.dart';
import '../modules/admin/doctor_leaves/admin_doctor_leaves_screen.dart';
import '../modules/admin/doctor_leaves/admin_doctor_leaves_binding.dart';
import '../modules/admin/verifications/admin_verifications_screen.dart';
import '../modules/admin/verifications/admin_verifications_binding.dart';
import '../modules/admin/appointments/admin_appointments_screen.dart';
import '../modules/admin/appointments/admin_appointments_binding.dart';

import 'app_routes.dart';

class AppPages {
  static final routes = [
    // Auth
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.registerEmail,
      page: () => RegisterEmailScreen(),
      binding: RegisterEmailBinding(),
    ),
    GetPage(
      name: AppRoutes.otpVerification,
      page: () => const OtpVerificationScreen(),
      binding: OtpVerificationBinding(),
    ),
    GetPage(
      name: AppRoutes.setPassword,
      page: () => const SetPasswordScreen(),
      binding: SetPasswordBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => LoginScreen(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordScreen(),
      binding: ForgotPasswordBinding(),
    ),

    // Student
    GetPage(
      name: AppRoutes.studentDashboard,
      page: () => const StudentDashboardScreen(),
      binding: StudentDashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.bookAppointment,
      page: () => const BookAppointmentScreen(),
      binding: BookAppointmentBinding(),
    ),
    GetPage(
      name: AppRoutes.myAppointments,
      page: () => const MyAppointmentsScreen(),
      binding: MyAppointmentsBinding(),
    ),
    GetPage(
      name: AppRoutes.healthAnalyzer,
      page: () => const HealthAnalyzerScreen(),
      binding: HealthAnalyzerBinding(),
    ),
    GetPage(
      name: AppRoutes.medicineReminders,
      page: () => const MedicineRemindersScreen(),
      binding: MedicineRemindersBinding(),
    ),
    GetPage(
      name: AppRoutes.medicalHistory,
      page: () => const MedicalHistoryScreen(),
      binding: MedicalHistoryBinding(),
    ),
    GetPage(
      name: AppRoutes.emergencyContacts,
      page: () => const EmergencyContactsScreen(),
      binding: EmergencyContactsBinding(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.prescriptionHistory,
      page: () => const PrescriptionHistoryScreen(),
      binding: PrescriptionHistoryBinding(),
    ),
    GetPage(
      name: AppRoutes.feedback,
      page: () => const FeedbackScreen(),
      binding: FeedbackBinding(),
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsScreen(),
      binding: NotificationsBinding(),
    ),

    // Faculty
    GetPage(
      name: AppRoutes.facultyDashboard,
      page: () => const FacultyDashboardScreen(),
      binding: FacultyDashboardBinding(),
    ),

    // Doctor
    GetPage(
      name: AppRoutes.doctorDashboard,
      page: () => const DoctorDashboardScreen(),
      binding: DoctorDashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.todayAppointments,
      page: () => const TodayAppointmentsScreen(),
      binding: TodayAppointmentsBinding(),
    ),
    GetPage(
      name: AppRoutes.patientDetail,
      page: () => const PatientDetailScreen(),
      binding: PatientDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.writePrescription,
      page: () => const WritePrescriptionScreen(),
      binding: WritePrescriptionBinding(),
    ),
    GetPage(
      name: AppRoutes.patients,
      page: () => const PatientsScreen(),
      binding: PatientsBinding(),
    ),
    GetPage(
      name: AppRoutes.schedule,
      page: () => const ScheduleScreen(),
      binding: ScheduleBinding(),
    ),
    GetPage(
      name: AppRoutes.bookingSettings,
      page: () => const BookingSettingsScreen(),
      binding: BookingSettingsBinding(),
    ),
    GetPage(
      name: AppRoutes.doctorProfile,
      page: () => const DoctorProfileScreen(),
      binding: DoctorProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.doctorSettings,
      page: () => const DoctorSettingsScreen(),
      binding: DoctorSettingsBinding(),
    ),
    GetPage(
      name: AppRoutes.doctorLeaves,
      page: () => const DoctorLeavesScreen(),
      binding: DoctorLeavesBinding(),
    ),

    // Appointment detail (shared)
    GetPage(
      name: AppRoutes.appointmentDetail,
      page: () => const AppointmentDetailScreen(),
    ),

    // Admin
    GetPage(
      name: AppRoutes.adminDashboard,
      page: () => const AdminDashboardScreen(),
      binding: AdminDashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.adminAppointments,
      page: () => const AdminAppointmentsScreen(),
      binding: AdminAppointmentsBinding(),
    ),
    GetPage(
      name: AppRoutes.manageUsers,
      page: () => const ManageUsersScreen(),
      binding: ManageUsersBinding(),
    ),
    GetPage(
      name: AppRoutes.manageDoctors,
      page: () => const ManageDoctorsScreen(),
      binding: ManageDoctorsBinding(),
    ),
    GetPage(
      name: AppRoutes.manageFeedback,
      page: () => const ManageFeedbackScreen(),
      binding: ManageFeedbackBinding(),
    ),
    GetPage(
      name: AppRoutes.reports,
      page: () => const ReportsScreen(),
    ),
    GetPage(
      name: AppRoutes.systemSettings,
      page: () => const SystemSettingsScreen(),
    ),
    GetPage(
      name: AppRoutes.adminDoctorLeaves,
      page: () => const AdminDoctorLeavesScreen(),
      binding: AdminDoctorLeavesBinding(),
    ),
    GetPage(
      name: AppRoutes.adminVerifications,
      page: () => const AdminVerificationsScreen(),
      binding: AdminVerificationsBinding(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
      binding: SettingsBinding(),
    ),
  ];
}
