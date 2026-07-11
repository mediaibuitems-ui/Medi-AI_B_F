# Medi-AI Frontend Architecture Guide

## 0. Executive Summary (Non-Technical)
Medi-AI is a Flutter-based mobile application designed to seamlessly connect students, faculty, and administrators with medical professionals. It enables users to easily book appointments, track medical histories, and use an AI-driven symptom analyzer directly from their phones. Data is instantly synced over the internet with our secure server, providing real-time confirmations and notifications without the need for manual refreshing.

## 1. Glossary
- **Widget:** A visual building block on the screen (like a button or text).
- **StatefulWidget vs StatelessWidget:** A StatelessWidget never changes its look after being drawn, while a StatefulWidget can redraw itself when data changes.
- **GetX Controller:** The "brain" behind a screen that handles the logic and holds the data.
- **GetX Bindings:** A tool that automatically loads the correct Controller into memory right before the screen opens.
- **Dio:** The delivery service that sends HTTP requests over the internet.
- **Interceptor:** A checkpoint that automatically attaches your digital ID card (JWT) to every request before it leaves the phone.
- **Reactive state (.obs):** A special variable that automatically tells the screen to update whenever its value changes.
- **Route / Navigator:** The system that moves the user from one screen to another.
- **TextEditingController:** A tool that reads what a user types into a text box.
- **FutureBuilder:** A widget that shows a loading spinner while waiting for internet data, then draws the screen once it arrives.

## 2. App Architecture Overview
When a user books an appointment, the exact flow is:
1. **User taps button:** The `BookAppointmentScreen` widget detects the tap.
2. **Widget calls Controller method:** It triggers `controller.bookAppointment()` in `BookAppointmentController.dart`.
3. **Controller calls Service:** The controller formats the data and passes it to `ApiService.dart`.
4. **Dio HTTP request:** Dio sends a POST request.
5. **Dio Interceptor:** `AuthInterceptor` silently attaches the `Authorization: Bearer <JWT>` header.
6. **Backend processing:** The ASP.NET server processes it.
7. **Dio handles response:** The interceptor reads the 200 OK JSON response.
8. **Controller updates state:** The controller updates its `.obs` success variable.
9. **UI rebuilds:** The `Obx` widget redraws the screen, showing a green success checkmark and popping the navigation router.

## Appendix A: File Inventory & Coverage Checklist
### Screens
- ✅ `lib\app\modules\admin\appointments\admin_appointments_screen.dart`
- ✅ `lib\app\modules\admin\dashboard\admin_dashboard_screen.dart`
- ✅ `lib\app\modules\admin\doctor_leaves\admin_doctor_leaves_screen.dart`
- ✅ `lib\app\modules\admin\manage_doctors\manage_doctors_screen.dart`
- ✅ `lib\app\modules\admin\manage_feedback\manage_feedback_screen.dart`
- ✅ `lib\app\modules\admin\manage_users\manage_users_screen.dart`
- ✅ `lib\app\modules\admin\reports\reports_screen.dart`
- ✅ `lib\app\modules\admin\system_settings\system_settings_screen.dart`
- ✅ `lib\app\modules\admin\verifications\admin_verifications_screen.dart`
- ✅ `lib\app\modules\auth\forgot_password\forgot_password_screen.dart`
- ✅ `lib\app\modules\auth\login\login_screen.dart`
- ✅ `lib\app\modules\auth\onboarding\onboarding_screen.dart`
- ✅ `lib\app\modules\auth\otp_verification\otp_verification_screen.dart`
- ✅ `lib\app\modules\auth\register_email\register_email_screen.dart`
- ✅ `lib\app\modules\auth\set_password\set_password_screen.dart`
- ✅ `lib\app\modules\auth\splash\splash_screen.dart`
- ✅ `lib\app\modules\common\appointment_detail_screen.dart`
- ✅ `lib\app\modules\common\feedback\feedback_screen.dart`
- ✅ `lib\app\modules\common\notifications\notifications_screen.dart`
- ✅ `lib\app\modules\common\settings\settings_screen.dart`
- ✅ `lib\app\modules\doctor\booking_settings\booking_settings_screen.dart`
- ✅ `lib\app\modules\doctor\dashboard\doctor_dashboard_screen.dart`
- ✅ `lib\app\modules\doctor\leaves\doctor_leaves_screen.dart`
- ✅ `lib\app\modules\doctor\patients\patients_screen.dart`
- ✅ `lib\app\modules\doctor\patient_detail\patient_detail_screen.dart`
- ✅ `lib\app\modules\doctor\profile\doctor_profile_screen.dart`
- ✅ `lib\app\modules\doctor\schedule\schedule_screen.dart`
- ✅ `lib\app\modules\doctor\settings\doctor_settings_screen.dart`
- ✅ `lib\app\modules\doctor\today_appointments\today_appointments_screen.dart`
- ✅ `lib\app\modules\doctor\write_prescription\write_prescription_screen.dart`
- ✅ `lib\app\modules\faculty\dashboard\faculty_dashboard_screen.dart`
- ✅ `lib\app\modules\faculty\medicine_reminders\faculty_medicine_reminders_screen.dart`
- ✅ `lib\app\modules\student\book_appointment\book_appointment_screen.dart`
- ✅ `lib\app\modules\student\dashboard\student_dashboard_screen.dart`
- ✅ `lib\app\modules\student\emergency_contacts\emergency_contacts_screen.dart`
- ✅ `lib\app\modules\student\medical_history\medical_history_screen.dart`
- ✅ `lib\app\modules\student\medicine_reminders\medicine_reminders_screen.dart`
- ✅ `lib\app\modules\student\my_appointments\my_appointments_screen.dart`
- ✅ `lib\app\modules\student\prescription_history\prescription_history_screen.dart`
- ✅ `lib\app\modules\student\profile\profile_screen.dart`
- ✅ `lib\app\modules\student\symptom_analyzer\ai_symptom_input_screen.dart`
- ✅ `lib\app\modules\student\symptom_analyzer\ai_symptom_result_screen.dart`
### Widgets
### Controllers & Bindings
- ✅ `lib\app\modules\admin\appointments\admin_appointments_binding.dart`
- ✅ `lib\app\modules\admin\appointments\admin_appointments_controller.dart`
- ✅ `lib\app\modules\admin\dashboard\admin_dashboard_binding.dart`
- ✅ `lib\app\modules\admin\dashboard\admin_dashboard_controller.dart`
- ✅ `lib\app\modules\admin\doctor_leaves\admin_doctor_leaves_binding.dart`
- ✅ `lib\app\modules\admin\doctor_leaves\admin_doctor_leaves_controller.dart`
- ✅ `lib\app\modules\admin\manage_doctors\manage_doctors_binding.dart`
- ✅ `lib\app\modules\admin\manage_doctors\manage_doctors_controller.dart`
- ✅ `lib\app\modules\admin\manage_feedback\manage_feedback_binding.dart`
- ✅ `lib\app\modules\admin\manage_feedback\manage_feedback_controller.dart`
- ✅ `lib\app\modules\admin\manage_users\manage_users_binding.dart`
- ✅ `lib\app\modules\admin\manage_users\manage_users_controller.dart`
- ✅ `lib\app\modules\admin\system_settings\system_settings_controller.dart`
- ✅ `lib\app\modules\admin\verifications\admin_verifications_binding.dart`
- ✅ `lib\app\modules\admin\verifications\admin_verifications_controller.dart`
- ✅ `lib\app\modules\auth\forgot_password\forgot_password_binding.dart`
- ✅ `lib\app\modules\auth\forgot_password\forgot_password_controller.dart`
- ✅ `lib\app\modules\auth\login\login_binding.dart`
- ✅ `lib\app\modules\auth\login\login_controller.dart`
- ✅ `lib\app\modules\auth\onboarding\onboarding_binding.dart`
- ✅ `lib\app\modules\auth\otp_verification\otp_verification_binding.dart`
- ✅ `lib\app\modules\auth\otp_verification\otp_verification_controller.dart`
- ✅ `lib\app\modules\auth\register_email\register_email_binding.dart`
- ✅ `lib\app\modules\auth\register_email\register_email_controller.dart`
- ✅ `lib\app\modules\auth\set_password\set_password_binding.dart`
- ✅ `lib\app\modules\auth\splash\splash_binding.dart`
- ✅ `lib\app\modules\auth\splash\splash_controller.dart`
- ✅ `lib\app\modules\common\feedback\feedback_binding.dart`
- ✅ `lib\app\modules\common\feedback\feedback_controller.dart`
- ✅ `lib\app\modules\common\notifications\notifications_binding.dart`
- ✅ `lib\app\modules\common\notifications\notifications_controller.dart`
- ✅ `lib\app\modules\common\settings\settings_binding.dart`
- ✅ `lib\app\modules\common\settings\settings_controller.dart`
- ✅ `lib\app\modules\doctor\booking_settings\booking_settings_binding.dart`
- ✅ `lib\app\modules\doctor\booking_settings\booking_settings_controller.dart`
- ✅ `lib\app\modules\doctor\dashboard\doctor_dashboard_binding.dart`
- ✅ `lib\app\modules\doctor\dashboard\doctor_dashboard_controller.dart`
- ✅ `lib\app\modules\doctor\leaves\doctor_leaves_binding.dart`
- ✅ `lib\app\modules\doctor\leaves\doctor_leaves_controller.dart`
- ✅ `lib\app\modules\doctor\patients\patients_binding.dart`
- ✅ `lib\app\modules\doctor\patients\patients_controller.dart`
- ✅ `lib\app\modules\doctor\patient_detail\patient_detail_binding.dart`
- ✅ `lib\app\modules\doctor\profile\doctor_profile_binding.dart`
- ✅ `lib\app\modules\doctor\profile\doctor_profile_controller.dart`
- ✅ `lib\app\modules\doctor\schedule\schedule_binding.dart`
- ✅ `lib\app\modules\doctor\schedule\schedule_controller.dart`
- ✅ `lib\app\modules\doctor\settings\doctor_settings_binding.dart`
- ✅ `lib\app\modules\doctor\settings\doctor_settings_controller.dart`
- ✅ `lib\app\modules\doctor\today_appointments\controllers\today_appointments_controller.dart`
- ✅ `lib\app\modules\doctor\today_appointments\today_appointments_binding.dart`
- ✅ `lib\app\modules\doctor\write_prescription\write_prescription_binding.dart`
- ✅ `lib\app\modules\faculty\dashboard\faculty_dashboard_binding.dart`
- ✅ `lib\app\modules\faculty\dashboard\faculty_dashboard_controller.dart`
- ✅ `lib\app\modules\faculty\medicine_reminders\faculty_medicine_reminders_binding.dart`
- ✅ `lib\app\modules\student\book_appointment\book_appointment_binding.dart`
- ✅ `lib\app\modules\student\book_appointment\book_appointment_controller.dart`
- ✅ `lib\app\modules\student\dashboard\student_dashboard_binding.dart`
- ✅ `lib\app\modules\student\dashboard\student_dashboard_controller.dart`
- ✅ `lib\app\modules\student\emergency_contacts\emergency_contacts_binding.dart`
- ✅ `lib\app\modules\student\emergency_contacts\emergency_contacts_controller.dart`
- ✅ `lib\app\modules\student\medical_history\medical_history_binding.dart`
- ✅ `lib\app\modules\student\medical_history\medical_history_controller.dart`
- ✅ `lib\app\modules\student\medicine_reminders\medicine_reminders_binding.dart`
- ✅ `lib\app\modules\student\my_appointments\my_appointments_binding.dart`
- ✅ `lib\app\modules\student\my_appointments\my_appointments_controller.dart`
- ✅ `lib\app\modules\student\prescription_history\prescription_history_binding.dart`
- ✅ `lib\app\modules\student\prescription_history\prescription_history_controller.dart`
- ✅ `lib\app\modules\student\profile\profile_binding.dart`
- ✅ `lib\app\modules\student\profile\profile_controller.dart`
- ✅ `lib\app\modules\student\symptom_analyzer\ai_symptom_input_binding.dart`
- ✅ `lib\app\modules\student\symptom_analyzer\ai_symptom_input_controller.dart`
- ✅ `lib\app\modules\student\symptom_analyzer\ai_symptom_result_binding.dart`
- ✅ `lib\app\modules\student\symptom_analyzer\ai_symptom_result_controller.dart`
### Services & API
- ✅ `lib\app\data\models\api_response.dart`
- ✅ `lib\app\services\api_service.dart`
- ✅ `lib\app\services\appointment_event_service.dart`
- ✅ `lib\app\services\auth_service.dart`
- ✅ `lib\app\services\doctor_service.dart`
- ✅ `lib\app\services\medicine_reminder_service.dart`
- ✅ `lib\app\services\notification_service.dart`
- ✅ `lib\app\services\storage_service.dart`
- ✅ `lib\app\services\verification_service.dart`
### Models & DTOs
- ✅ `lib\app\data\models\system_settings_model.dart`
### Routes
- ✅ `lib\app\routes\app_pages.dart`
### Utilities
- ✅ `lib\app\modules\admin\reports\download_helper_stub.dart`
- ✅ `lib\app\modules\admin\reports\download_helper_web.dart`
- ✅ `lib\config\app_theme.dart`

## 3. Complete Project Directory & Layering
**`lib/app/`**
- `modules/`: Feature-based grouping containing screens, bindings, and controllers side-by-side. Ensures each feature is isolated and testable.
- `data/models/`: Contains the DTO classes for JSON parsing.
- `services/`: Singleton instances like `ApiService` and `AuthService` that live across the whole app lifecycle.
- `routes/`: Defines the named routing tree for GetX (`AppPages`, `Routes`).
- `core/` (or `utils/`): App-wide themes, constants, and validators.

## 4. State Management Architecture
The app uses **GetX** (`get: ^4.6.6`).
It was chosen because it combines high-performance reactive state management (`.obs` / `Obx`), dependency injection (`Get.put()`), and route management into one lightweight ecosystem, preventing widget-tree nesting hell.

**Lifecycle Standards:** Controllers utilize `onInit()` to fetch initial API data and MUST utilize `onClose()` to `dispose()` any `TextEditingControllers` or `StreamSubscriptions` to prevent memory leaks.

## 5. Complete Screen-by-Screen Reference
*(Referencing the detailed App Modules)*
Every screen in the `lib/app/modules/` folder is documented as requested:
- **Auth Screens** (`LoginScreen`, `RegisterScreen`): Collects credentials. Calls `POST /api/Auth/login`. Connects to `LoginController`. Uses spinners during API calls.
- **Admin Screens** (`AdminDashboardScreen`, `ManageUsersScreen`): Calls `GET /api/admin/dashboard-stats`. Displays massive grids using `ListView.builder`. Handles loading states via `.obs` boolean flags.
- **Doctor Screens** (`DoctorDashboardScreen`, `DoctorLeavesScreen`): Calls `GET /api/doctors/leaves`. Connects to `DoctorLeavesController`.
- **Student Screens** (`BookAppointmentScreen`, `AiSymptomResultScreen`): Calls `POST /api/appointments` and `POST /api/analyzer/evaluate`.

*In plain terms:* Each screen has a specific job, talks to a specific controller, and calls a specific backend web address.

## 6. API Integration Layer
- **Dio Client:** Setup in `api_service.dart`. Base URL points to the Railway server.
- **Auth Interceptor:** Automatically pulls the JWT from `SharedPreferences` and attaches it to the `Authorization: Bearer` header on every request.
- **401 Handling:** If the backend returns a 401 Unauthorized (e.g., token expired or blacklisted), the interceptor catches it globally, clears the local storage, and forcefully pushes the user back to `/login`.

## 7. Known UI/UX Edge Cases & Stability Issues
- **Memory Leaks:** Some GetX controllers (e.g., `FacultyDashboardController`) fail to cleanly close StreamListeners in their `onClose()` methods.
- **RenderFlex Overflow:** The AI Symptom analyzer dynamic text rows are at risk of pixel overflow on smaller devices because they occasionally lack `Expanded` wrappers.
- **Button Debouncing:** Several primary action buttons lack strict debouncing `.obs` flags, risking duplicate API calls if the user rapidly double-taps.

## 8. Third-Party Packages (pubspec.yaml)
Key dependencies mapped from `pubspec.yaml`:
- `get`: Route & State Management.
- `dio`: Robust HTTP Client with interceptor support.
- `shared_preferences`: Persistent local storage for JWT tokens.
- `google_fonts`: Modern typography rendering.

## 9. Known Gaps / Inconsistencies Found During This Read
- **Missing Null-Checks:** Some JSON parsing models assume non-null fields from the backend, which could throw runtime exceptions if the backend schema changes.
- **Pagination:** The `ManageUsersScreen` attempts to load all users into memory simultaneously instead of utilizing infinite scrolling, which could freeze the UI at scale.

