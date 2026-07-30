class AppRoutes {
  // Auth Routes
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const registerEmail = '/register-email';
  static const otpVerification = '/otp-verification';
  static const setPassword = '/set-password';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';

  // Student Routes
  static const studentDashboard = '/student-dashboard';
  static const bookAppointment = '/book-appointment';
  static const myAppointments = '/my-appointments';

  static const symptomAnalyzerInput = '/symptom-analyzer-input';
  static const symptomAnalyzerResult = '/symptom-analyzer-result';
  static const symptomAnalyzerHistory = '/symptom-analyzer-history';
  static const medicineReminders = '/medicine-reminders';
  static const medicalHistory = '/medical-history';
  static const emergencyContacts = '/emergency-contacts';
  static const profile = '/profile';
  static const prescriptionHistory = '/prescription-history';
  static const feedback = '/feedback';

  // Doctor Routes
  static const doctorDashboard = '/doctor-dashboard';
  static const todayAppointments = '/today-appointments';
  static const patientDetail = '/patient-detail';
  static const writePrescription = '/write-prescription';
  static const appointmentDetail = '/appointment-detail';
  static const patients = '/patients';
  static const schedule = '/schedule';
  static const bookingSettings = '/booking-settings';
  static const doctorProfile = '/doctor-profile';
  static const doctorSettings = '/doctor-settings';
  static const doctorLeaves = '/doctor/leaves';

  // Faculty Routes
  static const facultyDashboard = '/faculty-dashboard';
  static const facultyMedicineReminders = medicineReminders;

  // Admin Routes
  static const adminDashboard = '/admin-dashboard';
  static const adminAppointments = '/admin-appointments';
  static const manageUsers = '/manage-users';
  static const manageDoctors = '/manage-doctors';
  static const manageFeedback = '/manage-feedback';
  static const systemSettings = '/system-settings';
  static const reports = '/reports';
  static const adminDoctorLeaves = '/admin/doctor-leaves';
  static const adminVerifications = '/admin/verifications';

  // Common Routes
  static const notifications = '/notifications';
  static const settings = '/settings';
}
